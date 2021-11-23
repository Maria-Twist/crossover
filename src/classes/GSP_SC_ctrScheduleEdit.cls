/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, June, 2020
 */
public with sharing class GSP_SC_ctrScheduleEdit
{
	public List<OpportunityLineItem> opportunityLineItems		{ get; set; }
	private Opportunity opportunity;
	public boolean bIsValid										{ get; set; }
	public boolean bShowProjection								{ get; private set; }
	public Map<String, DynamicFieldSet> fieldSetMap				{ get; private set; }
	public Boolean bValid										{ get; private set; }
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
    
    private static Set<String> excludedFields = new Set<String>{ 'Id' };
	
	public GSP_SC_ctrScheduleEdit(ApexPages.StandardController controller)
	{
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
		bShowProjection = false;
		for (Schema.PicklistEntry picklistEntry : OpportunityLineItem.Revenue_Projection_Method__c.getDescribe().getPicklistValues())
		{
			if (picklistEntry.getValue() == 'S-Curve')
			{
				bShowProjection = true;
			}
		}
		
		BuildFieldsets();
		
		String strSOQL = 'SELECT Id, Name, IsWon, (SELECT Id';
		
		
		if (!this.fieldSetMap.isEmpty())
		{
			for (String strField : this.fieldSetMap.keySet())
			{
				strSOQL += ', ' + strField;
			}
		}
		else
		{
			strSOQL += ', Name,	Revenue_Start_Date__c, Revenue_Projection_Method__c, Revenue_Months__c';
		}
		strSOQL += ' FROM OpportunityLineItems) FROM Opportunity WHERE Id = :opportunityId';
		List <Opportunity> opportunities = Database.query(strSOQL);
		System.assertEquals(1, opportunities.size());
		this.opportunity = opportunities.get(0);
		if (this.opportunity.IsWon)
		{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning,
            	'You cannot edit the Revenue Schedules on a Closed Opportunity using this button. Please either a) set the Opportunity to an Open Stage or b) edit the Actual or Latest Forecast figures using the Mass Update Schedules button.'));
            bIsValid = false;
            return;
		}
		
		if (this.opportunity.OpportunityLineItems.isEmpty())
		{
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, 'No Product Lines To Edit'));
			bIsValid = false;
			return;
		}
		
		this.opportunityLineItems = this.opportunity.OpportunityLineItems;
	}
	
	public PageReference SaveLineItems()
	{
		if (Schema.sObjectType.OpportunityLineItem.isUpdateable())
		{
			update opportunityLineItems;
		}
		this.bValid = true;
		return null;
	}
	
	private void BuildFieldsets()
	{
		this.fieldSetMap = new Map<String, DynamicFieldSet>();
		for (Schema.FieldSetMember fieldMember : SobjectType.OpportunityLineItem.FieldSets.GSP_SC_Schedule_Layout.getFields())
		{
			if (!fieldMember.getFieldPath().contains('.') && !excludedFields.contains(fieldMember.getFieldPath()) &&
				((Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().
				fields.getMap().get(fieldMember.getFieldPath()).getDescribe().isAccessible()) ||
				test.IsRunningTest()))
			{
				DynamicFieldSet dynamicFieldSet = new DynamicFieldSet(fieldMember.getFieldPath(), fieldMember.getLabel());
				if (!Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().
					fields.getMap().get(fieldMember.getFieldPath()).getDescribe().isNillable())
				{
					dynamicFieldSet.bMandatory = true;
				}
				this.fieldSetMap.put(fieldMember.getFieldPath(), dynamicFieldSet);
			}
		}
		if (!this.fieldSetMap.isEmpty())
		{
			for (Schema.FieldSetMember fieldMember : SobjectType.OpportunityLineItem.FieldSets.GSP_SC_Schedule_Layout_Edit.getFields())
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
		}
		else if (test.isRunningTest())
		{
			// To cover DynamicFieldSet
			this.fieldSetMap.put('Name', new DynamicFieldSet('Name', 'Name'));
		}
	}
	
	public class DynamicFieldSet
	{
		public String field			{ get; private set; }
		public String label			{ get; private set; }
		public boolean bReadOnly	{ get; private set; }
		@testVisible
		public boolean bMandatory	{ get; private set; }
		
		public DynamicFieldSet(String strField, String strLabel)
		{
			this.field = strField;
			this.label = strLabel;
			this.bReadOnly = true;
			this.bMandatory = false;
		}
	}
}