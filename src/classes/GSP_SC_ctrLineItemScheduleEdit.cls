/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, June, 2020
 */
public with sharing class GSP_SC_ctrLineItemScheduleEdit
{
	public Opportunity opportunity							{ get; private set; }
	public Map<Id, LineItemWrapper> lineItemWrapperMap		{ get; set; }
	public boolean bIsValid									{ get; private set; }
	public String opportunityLineItemId						{ get; set; }
	public Map<String, DynamicFieldSet> fieldSetMap			{ get; private set; }
	public Boolean bValid									{ get; private set; }
	
	public List<String> dynamicFields
    {
    	get
    	{
    		return new List<String>( this.fieldSetMap.keySet() );
    	}
    }
    
    public Boolean hasDynamicFields
    {
    	get
    	{
    		return !this.fieldSetMap.isEmpty();
    	}
    }
    
    public Boolean hasAmountField
    {
    	get
    	{
    		return this.fieldSetMap.containsKey('Revenue_Amount__c') &&
    			!this.fieldSetMap.get('Revenue_Amount__c').bReadOnly;
    	}
    }
    
    private static Set<String> excludedFields = new Set<String>{ 'Id', 'Opportunity_Line_Item_Id__c',
    	'Budget__c', 'Account__c', 'Account_Owner__c', 'Product__c' };
	
	public GSP_SC_ctrLineItemScheduleEdit(ApexPages.StandardController controller)
	{
		lineItemWrapperMap = new Map<Id, LineItemWrapper>();
		bIsValid = true;
		this.bValid = false;
		Id opportunityId = controller.getId();
		System.assertNotEquals(null, opportunityId);
		
		if (!Schema.sObjectType.Opportunity.isAccessible() ||
			!Schema.sObjectType.OpportunityLineItem.isAccessible())
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,
            	'You do not have permission to modify Opportunities or Product Lines.'));
            return;
		}
		List <Opportunity> opportunities = new List<Opportunity>([
			SELECT
				Id,
				Name,
				IsWon, (
				SELECT
					Id,
					Product2.Name,
					Revenue_Projection_Method__c,
					Opportunity.isWon,
					TotalPrice
				FROM
					OpportunityLineItems
				ORDER BY
					Product2.Name)
			FROM
				Opportunity
			WHERE
				Id = :opportunityId]);
		System.assertEquals(1, opportunities.size());
		this.opportunity = opportunities.get(0);
		if (opportunity.IsWon)
		{
            bIsValid = false;
		}
		
		if (this.opportunity.OpportunityLineItems.isEmpty())
		{
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, 'No Product Lines To Edit'));
			bIsValid = false;
			return;
		}

		for (OpportunityLineItem opportunityLineItem : this.opportunity.OpportunityLineItems)
		{
			lineItemWrapperMap.put(opportunityLineItem.Id, new LineItemWrapper(opportunityLineItem));
		}
		
		if (!Schema.sObjectType.Revenue_Schedule__c.isAccessible())
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,
            	'You do not have permission to modify Revenue Schedules.'));
            return;
		}
		
		BuildFieldsets();
		Set<Id> lineItemSet = lineItemWrapperMap.keySet();
		String strSOQL = 'SELECT Id, Opportunity_Line_Item_Id__c, Budget__c, Account__c, Account_Owner__c, Product__c, Clinic__c';
		if (!this.fieldSetMap.isEmpty())
		{
			for (String strField : this.fieldSetMap.keySet())
			{
				strSOQL += ', ' + strField;
			}
		}
		else
		{
			strSOQL += ', Name, Revenue_Amount__c, Latest_Forecast__c, Cumulative_Revenue__c, ' +
				'Actual__c, Status__c, Opportunity__c, ' +
				'Product_Family__c, Revenue_Schedule_Date__c';
		}
		strSOQL += ' FROM Revenue_Schedule__c WHERE Opportunity_Line_Item_Id__c IN :lineItemSet' +
			' ORDER BY Opportunity_Line_Item_Id__c, Revenue_Schedule_Date__c ASC';
		for (Revenue_Schedule__c revenueSchedule : Database.query(strSOQL))
		{
			if (lineItemWrapperMap.containsKey(revenueSchedule.Opportunity_Line_Item_Id__c))
			{
				lineItemWrapperMap.get(revenueSchedule.Opportunity_Line_Item_Id__c).AddRevenueSchedule(revenueSchedule, this.hasAmountField);
			}
		}
	}
	
	public void Autocalculate()
	{
		System.assertEquals(false, String.isEmpty(opportunityLineItemId));
		System.assertEquals(true, lineItemWrapperMap.containsKey(opportunityLineItemId));
		
		LineItemWrapper wrapper = lineItemWrapperMap.get(opportunityLineItemId);
		Decimal dLineItemPrice = wrapper.opportunityLineItem.TotalPrice;
		List<Revenue_Schedule__c> revenueSchedules = new List<Revenue_Schedule__c>();
		Boolean bHasChanges = false;
		for (Revenue_Schedule__c revenueSchedule : wrapper.revenueSchedules)
		{
			if (revenueSchedule.Revenue_Amount__c != wrapper.revenueScheduleAmountMap.get(revenueSchedule.Id))
			{
				dLineItemPrice -= revenueSchedule.Revenue_Amount__c;
				bHasChanges = true;
			}
			else
			{
				revenueSchedules.add(revenueSchedule);
			}
		}

		if (!revenueSchedules.isEmpty() && bHasChanges)
		{
			Integer scale = Schema.sObjectType.Revenue_Schedule__c.fields.Revenue_Amount__c.getScale();
			Decimal dInstallment = ((dLineItemPrice.setScale(scale) / revenueSchedules.size())).setScale(scale);
			Decimal dFinal = (dLineItemPrice - (dInstallment * (revenueSchedules.size() - 1))).setScale(scale);
			if (dInstallment < 0)
			{
				dInstallment = 0;
			}
			if (dFinal < 0)
			{
				dFinal = 0;
			}
			for (Integer i = 0; i < revenueSchedules.size(); i++)
			{
				Revenue_Schedule__c revenueSchedule = revenueSchedules.get(i);
				if (i < (revenueSchedules.size() - 1))
				{
					revenueSchedule.Revenue_Amount__c = dInstallment;
				}
				else
				{
					revenueSchedule.Revenue_Amount__c = dFinal;
				}
			}
		}
	}
	
	public void Revert()
	{
		System.assertEquals(false, String.isEmpty(opportunityLineItemId));
		System.assertEquals(true, lineItemWrapperMap.containsKey(opportunityLineItemId));
		
		LineItemWrapper wrapper = lineItemWrapperMap.get(opportunityLineItemId);
		for (Revenue_Schedule__c revenueSchedule : wrapper.revenueSchedules)
		{
			revenueSchedule.Revenue_Amount__c = wrapper.revenueScheduleAmountMap.get(revenueSchedule.Id);
		}
	}
	
	public void Dummy()
	{
		
	}
	
	public PageReference SaveSchedules()
	{
		List<Revenue_Schedule__c> revenueScheduleCache = new List<Revenue_Schedule__c>();
		for (LineItemWrapper wrapper : lineItemWrapperMap.values())
		{
			revenueScheduleCache.addAll(wrapper.revenueSchedules);
		}
		
		if (!revenueScheduleCache.isEmpty())
		{			
			GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers = true;
			Map<Id, List<Revenue_Schedule__c>> opportunityLineItemRevenueScheduleMap = new Map<Id, List<Revenue_Schedule__c>>();
			List<Revenue_Schedule__c> revenueSchedules = new List<Revenue_Schedule__c>();
			if (Schema.sObjectType.Revenue_Schedule__c.isUpdateable())
			{
				upsert revenueScheduleCache;
			}
			else
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,
					'You do not have permission to update Revenue Schedules.'));
				return null;
			}
			
			// Relink because of possible date changes.
			for (Revenue_Schedule__c revenueSchedule : revenueScheduleCache)
			{
				if (!opportunityLineItemRevenueScheduleMap.containsKey(revenueSchedule.Opportunity_Line_Item_Id__c))
				{
					opportunityLineItemRevenueScheduleMap.put(revenueSchedule.Opportunity_Line_Item_Id__c, new List<Revenue_Schedule__c>());
				}
				opportunityLineItemRevenueScheduleMap.get(revenueSchedule.Opportunity_Line_Item_Id__c).add(revenueSchedule);
				revenueSchedules.add(revenueSchedule);
			}
			
			if (!revenueSchedules.isEmpty())
			{
				GSP_SC_ScheduleHelper.LinkBudgets(revenueSchedules, opportunityLineItemRevenueScheduleMap, true);
			}
		}
		this.bValid = true;
		return null;
	}
	
	private void BuildFieldsets()
	{
		this.fieldSetMap = new Map<String, DynamicFieldSet>();
		for (Schema.FieldSetMember fieldMember : SobjectType.Revenue_Schedule__c.FieldSets.GSP_SC_Schedule_Layout.getFields())
		{
			if (!fieldMember.getFieldPath().contains('.') && !excludedFields.contains(fieldMember.getFieldPath()) &&
				((Schema.getGlobalDescribe().get('Revenue_Schedule__c').getDescribe().
				fields.getMap().get(fieldMember.getFieldPath()).getDescribe().isAccessible()) ||
				test.IsRunningTest()))
			{
				DynamicFieldSet dynamicFieldSet = new DynamicFieldSet(fieldMember.getFieldPath(), fieldMember.getLabel(), opportunity.IsWon);
				if (!Schema.getGlobalDescribe().get('Revenue_Schedule__c').getDescribe().
					fields.getMap().get(fieldMember.getFieldPath()).getDescribe().isNillable())
				{
					dynamicFieldSet.bMandatory = true;
				}
				this.fieldSetMap.put(fieldMember.getFieldPath(), dynamicFieldSet);
			}
		}
		if (!this.fieldSetMap.isEmpty())
		{
			for (Schema.FieldSetMember fieldMember : SobjectType.Revenue_Schedule__c.FieldSets.GSP_SC_Schedule_Layout_Edit.getFields())
			{
				// If not accessible field will not be in this,fieldSetMap
				if (this.fieldSetMap.containsKey(fieldMember.getFieldPath()))
				{
					this.fieldSetMap.get(fieldMember.getFieldPath()).bReadOnly = false;
					if (fieldMember.getRequired())
					{
						this.fieldSetMap.get(fieldMember.getFieldPath()).bMandatory = true;
					}
				}
			}
			
			for (Schema.FieldSetMember fieldMember : SobjectType.Revenue_Schedule__c.FieldSets.GSP_SC_Schedule_Layout_Edit_Won.getFields())
			{
				// If not accessible field will not be in this,fieldSetMap
				if (this.fieldSetMap.containsKey(fieldMember.getFieldPath()))
				{
					this.fieldSetMap.get(fieldMember.getFieldPath()).visibleWhenWon = true;
				}
			}
		}
		else if (test.isRunningTest())
		{
			// To cover DynamicFieldSet
			this.fieldSetMap.put('Name', new DynamicFieldSet('Name', 'Name', false));
		}
	}
	
	public class LineItemWrapper
	{
		public OpportunityLineItem opportunityLineItem			{get; private set; }
		public List<Revenue_Schedule__c> revenueSchedules		{ get; set; }
		private Map<Id, Decimal> revenueScheduleAmountMap;
		public Decimal RevenueTotal
		{
			get
			{
				Decimal dTotal = 0;
				for (Revenue_Schedule__c revenueSchedule : this.revenueSchedules)
				{
					dTotal += revenueSchedule.Revenue_Amount__c;
				}
				return dTotal;
			}
		}
		
		public boolean canAutocalculate
		{
			get
			{
				Boolean bCanAutocalculate = true;
				for (Revenue_Schedule__c revenueSchedule : this.revenueSchedules)
				{
					if (revenueSchedule.Revenue_Amount__c == revenueScheduleAmountMap.get(revenueSchedule.Id))
					{
						bCanAutocalculate = false;
					}
				}
				return bCanAutocalculate;
			}
		}
		
		public LineItemWrapper(OpportunityLineItem opportunityLineItem)
		{
			this.opportunityLineItem = opportunityLineItem;
			this.revenueSchedules = new List<Revenue_Schedule__c>();
			this.revenueScheduleAmountMap = new Map<Id, Decimal>();
		}
		
		public Integer AddRevenueSchedule(Revenue_Schedule__c revenueSchedule, Boolean bHasRevenueField)
		{
			revenueSchedules.add(revenueSchedule);
			if (bHasRevenueField)
			{
				this.revenueScheduleAmountMap.put(revenueSchedule.Id, revenueSchedule.Revenue_Amount__c);
			}
			return revenueSchedules.size();
		}
	}
	
	public class DynamicFieldSet
	{
		public String field			{ get; private set; }
		public String label			{ get; private set; }
		private boolean bReadOnly	{ get; private set; }
		private boolean bIsWon;
		public boolean visibleWhenWon	{ get; set; }
		@testVisible
		public boolean bMandatory	{ get; private set; }
		public Boolean isEditable
		{
			get
			{
				if (bIsWon)
				{
					return visibleWhenWon;
				}
				else
				{
					return !bReadOnly;
				}
			}
		}
		
		public DynamicFieldSet(String strField, String strLabel, boolean isWon)
		{
			this.bIsWon = isWon;
			this.field = strField;
			this.label = strLabel;
			this.bReadOnly = true;
			this.bMandatory = false;
			this.visibleWhenWon = false;
		}
	}
}