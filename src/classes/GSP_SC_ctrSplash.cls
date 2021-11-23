/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, June, 2020
 */
public with sharing class GSP_SC_ctrSplash
{
	public boolean bHasDefaultSchedules		{ get; private set; }
	public boolean bHasScheduleTemplates	{ get; private set; }
	public String projectionType			{ get; set; }
	public boolean bConfirm					{ get; set; }
	public boolean bIsExecuting				{ get; private set; }
	public Integer interval					{ get; set; }
	public Boolean bDisableCloseDateChanges	{ get; set; }
	public String intervalFrequency			{ get; set; }
	
	public List<SelectOption> projectionTypes
	{
		get
		{
			List<SelectOption> options = new List<SelectOption>();
			
			options.add(new SelectOption('Straight Line', 'Straight Line'));
			if (bHasScheduleTemplates)
			{
				options.add(new SelectOption('S-Curve', 'S-Curve'));
			}
			return options;
		}
	}
	
	public List<SelectOption> intervalFrequencyList
	{
		get
		{
			List<SelectOption> options = new List<SelectOption>();
			
			options.add(new SelectOption('D', 'Days'));
			options.add(new SelectOption('M', 'Months'));
			options.add(new SelectOption('Y', 'Years'));
			return options;
		}
	}
	
	public GSP_SC_ctrSplash()
	{
		this.bHasDefaultSchedules = Schema.getGlobalDescribe().containsKey('OpportunityLineItemSchedule');
		String strSOQL = 'SELECT count() FROM'; 
		if (Type.forName('GSPProdSched__Revenue_Schedule_Template__c') != null)
		{
			strSOQL += ' GSPProdSched__Revenue_Schedule_Template__c';
		}
		else
		{
			strSOQL += ' Revenue_Schedule_Template__c';
		}
		
		this.bHasScheduleTemplates = Database.countQuery(strSOQL) > 0;
		this.bIsExecuting = false;
		this.bConfirm = false;
		this.interval = 1;
		this.intervalFrequency = 'M';
		this.bDisableCloseDateChanges = false;
	}
	
	public PageReference ChangeFrequency()
	{
		System.assertNotEquals(null, this.interval);
		Schedule_Settings__c setting = null;
		List<Schedule_Settings__c> settings2Delete = new List<Schedule_Settings__c>();
		for (Schedule_Settings__c settings : [
			SELECT
				Id,
				Name,
				Global_Schedule_Interval__c
			FROM
				Schedule_Settings__c
			LIMIT 500])
		{
			if (settings.Name == 'Default')
			{
				setting = settings;
			}
			else
			{
				settings2Delete.add(settings);
			}
		}
		
		if (!settings2Delete.isEmpty())
		{
			delete settings2Delete;
		}
				 
		if (setting == null)
		{
			setting = new Schedule_Settings__c(
				Name = 'Default');
		}
		setting.Global_Schedule_Interval__c = this.intervalFrequency + String.valueOf(this.interval);
		setting.Disable_Close_Date_Updates__c = this.bDisableCloseDateChanges;
		upsert setting;	
		return null;
	}
	
	public PageReference LoadScurveData()
	{
		if (!Schema.sObjectType.Revenue_Schedule_Template__c.isAccessible())
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,
            	'You do not have permission to modify Revenue Schedule Templates.'));
		}
		List<Decimal> valueList = new List<Decimal>{  0.091188197, 0.011372911, 0.012789694, 0.014382539, 0.016173212,
			0.018186137, 0.020448714, 0.022991676, 0.025849476, 0.029060722, 0.032668659, 0.036721702, 0.041274015,
			0.046386157, 0.052125785, 0.058568417, 0.065798264, 0.073909125, 0.083005345, 0.104630146, 0.117429573,
			0.131758301, 0.147789534, 0.165713607, 0.185739007, 0.208093275, 0.233023693, 0.260797684, 0.291702793,
			0.326046131, 0.364153091, 0.406365167, 0.453036626, 0.504529787, 0.561208621, 0.623430367, 0.691534874,
			0.765831369, 0.846582431, 0.933985020, 1.028148574, 1.129070388, 1.236608761, 1.350454776, 1.470103973,
			0.093202836, 1.594829670, 1.723660143, 1.855362314, 1.988434901, 2.121114045, 2.251394196, 2.377066400,
			2.495775000, 2.605092288, 2.702608671, 2.786034054, 2.853304077, 2.902683553, 2.932858680, 2.943009907,
			2.932858680, 2.902683553, 2.853304077, 2.786034054, 2.702608671, 2.605092288, 2.495775002, 2.377066400,
			2.251394196, 2.121114045, 1.988434901, 1.855362314, 1.723660143, 1.594829670, 1.470103973, 1.350454776,
			1.236608761, 1.129070388, 1.028148574, 0.933985020, 0.846582431, 0.765831369, 0.691534874, 0.623430367,
			0.561208621, 0.504529787, 0.453036626, 0.406365167, 0.364153091, 0.326046131, 0.291702793, 0.260797684,
			0.233023693, 0.208093275, 0.185739007, 0.165713607, 0.147789534, 0.131758301, 0.117429573, 0.104630146,
			0.093202836, 0.083005345, 0.073909125, 0.065798264, 0.058568417, 0.052125785, 0.046386157, 0.041274015,
			0.036721702, 0.032668659, 0.029060722, 0.025849476, 0.022991676, 0.020448714, 0.018186137, 0.016173212,
			0.014382539, 0.012789694, 0.011372911 };
			
		List<Revenue_Schedule_Template_Line_Item__c> revenueScheduleTemplateLineItemCache = new List<Revenue_Schedule_Template_Line_Item__c>();
		Integer i;
		
		List<Revenue_Schedule_Template__c> revenueScheduleTemplates = new List<Revenue_Schedule_Template__c>([
			SELECT
				Id
			FROM
				Revenue_Schedule_Template__c
			LIMIT 100]);
		if (Schema.sObjectType.Revenue_Schedule_Template__c.isDeletable())
		{
			delete revenueScheduleTemplates;
		}
		
		if (Schema.sObjectType.Revenue_Schedule_Template__c.isCreateable() &&
			Schema.sObjectType.Revenue_Schedule_Template_Line_Item__c.isCreateable())
		{
			Revenue_Schedule_Template__c revenueScheduleTemplate = new Revenue_Schedule_Template__c(
				Name = 'S-Curve',
				Type__c = 'S-Curve',
				Duration_Months__c = valueList.size());
			insert revenueScheduleTemplate;
			System.assertNotEquals(revenueScheduleTemplate.Id, null);

			i = 1;
			Decimal dCumulativeTotal = 0;
			for (Decimal dValue : valueList)
			{
				dCumulativeTotal += dValue;
				Revenue_Schedule_Template_Line_Item__c revenueScheduleTemplateLineItem = new Revenue_Schedule_Template_Line_Item__c(
					Value_This_Month__c = dValue,
					Revenue_Schedule_Template__c = revenueScheduleTemplate.Id,
					Name = String.valueOf(i),
					Month__c = i++,
					Cumulative_Value__c = dCumulativeTotal);
				revenueScheduleTemplateLineItemCache.add(revenueScheduleTemplateLineItem);
			}
			insert revenueScheduleTemplateLineItemCache;
			
			for (i = 1; i < revenueScheduleTemplateLineItemCache.size(); i++)
			{
				revenueScheduleTemplateLineItemCache.get(i).Previous_Month_Line_Item__c = revenueScheduleTemplateLineItemCache.get(i - 1).Id;
			}
			if (Schema.sObjectType.Revenue_Schedule_Template__c.isUpdateable())
			{
				update revenueScheduleTemplateLineItemCache;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,
					'SCurve data successfully created.'));
			}
			else
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,
					'You do not have permission to update Revenue Schedule Templates.'));
			}
			
		}
		return null;
	}
	
	public PageReference ConvertSalesforceSchedules()
	{
		if (!bConfirm)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,
				'Please check the Confirm checkbox to show you understand that all Schedules will be deleted.'));
			return null;
		}
		System.assertNotEquals(true, String.isEmpty(projectionType));
		GSP_SC_BatchUpdateSchedules batchJob = new GSP_SC_BatchUpdateSchedules(projectionType);
		Id batchId = Database.executebatch(batchJob, 20);
		this.bIsExecuting = true;
		return null;
	}
}