/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, June, 2020
 */
@isTest
private class GSP_SC_ctrSplash_TEST
{
	@isTest
	private static void test_GSP_SC_ctrSplash()
	{		
		List<Decimal> valueList = new List<Decimal>{ 0.009802731, 0.0120568214, 0.013473605,
			0.015066450, 0.016857123, 0.018870048, 0.021132625, 0.023675587, 0.026533387, 0.029744633, 0.033352570, 0.037405613,
			0.041957926, 0.047070068, 0.052809696, 0.059252328, 0.066482175, 0.074593036, 0.083689256, 0.093886800, 0.105314057,
			0.118113484, 0.132442212, 0.148473445, 0.166397518, 0.186422918, 0.208777186, 0.233707604, 0.261481595, 0.292386704,
			0.326730042, 0.364837002, 0.407049078, 0.453720537, 0.505213698, 0.561892532, 0.624114278, 0.692218785, 0.766515280,
			0.847266342, 0.934668931, 1.028832485, 1.129754299, 1.237292672, 1.351138687, 1.470787884, 1.595513581, 1.724344054,
			1.856046225, 1.989118812, 2.121797956, 2.252078107, 2.377750311, 2.496458911, 2.605776199, 2.703292582, 2.786717965,
			2.853987988, 2.903367464, 2.933542591, 2.943693818, 2.933542591, 2.903367464, 2.853987988, 2.786717965, 2.703292582,
			2.605776199, 2.496458913, 2.377750311, 2.252078107, 2.121797956, 1.989118812, 1.856046225, 1.724344054, 1.595513581,
			1.470787884, 1.351138687, 1.237292672, 1.129754299, 1.028832485, 0.934668931, 0.847266342, 0.766515280, 0.692218785,
			0.624114278, 0.561892532, 0.505213698, 0.453720537, 0.407049078, 0.364837002, 0.326730042, 0.292386704, 0.261481595,
			0.233707604, 0.208777186, 0.186422918, 0.166397518, 0.148473445, 0.132442212, 0.118113484, 0.105314057, 0.093886747,
			0.083689256, 0.074593036, 0.066482175, 0.059252328, 0.052809696, 0.047070068, 0.041957926, 0.037405613, 0.033352570,
			0.029744633, 0.026533387, 0.023675587, 0.021132625, 0.018870048, 0.016857123, 0.015066450, 0.013473605, 0.012056822 };

		List<Revenue_Schedule_Template_Line_Item__c> revenueScheduleTemplateLineItemCache = new List<Revenue_Schedule_Template_Line_Item__c>(); 
		Integer i;
		
		List<Revenue_Schedule_Template__c> revenueScheduleTemplates = new List<Revenue_Schedule_Template__c>([
			SELECT
				Id,
				Type__c, (
				SELECT
					Id
				FROM
					Revenue_Schedule_Template_Line_Items__r)
			FROM
				Revenue_Schedule_Template__c]);
		if (revenueScheduleTemplates.isEmpty())
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
			update revenueScheduleTemplateLineItemCache;
		}
		PageReference pageReference = Page.GSP_SC_Splash;
		System.Test.setCurrentPage(pageReference);
		
		GSP_SC_ctrSplash controller = new GSP_SC_ctrSplash();
		System.assertEquals(false, controller.projectionTypes.isEmpty());
		System.assertEquals(false, controller.intervalFrequencyList.isEmpty());
		System.assertEquals(null, controller.projectionType);
		System.assertEquals(false, controller.bConfirm);
		try
		{
			System.assert(null, controller.LoadScurveData());
		}
		catch (Exception ex){}
		if (Schema.getGlobalDescribe().containsKey('OpportunityLineItemSchedule'))
		{
			controller.bConfirm = true;
			controller.projectionType = 'Straight Line';
			controller.ConvertSalesforceSchedules();
		}
		
		Schedule_Settings__c scheduleSettings = new Schedule_Settings__c(
			Name = 'Test',
			Global_Schedule_Interval__c = 'Y1');
		insert scheduleSettings;
		System.assertNotEquals(null, scheduleSettings);
		
		controller.intervalFrequency = 'M';
		controller.interval = 1;
		controller.ChangeFrequency();
		
		List<Schedule_Settings__c> testSettings = new List<Schedule_Settings__c>([
			SELECT
				Id,
				Name,
				Global_Schedule_Interval__c
			FROM
				Schedule_Settings__c]);
		System.assertEquals(1, testSettings.size());
		Schedule_Settings__c testSetting = testSettings.get(0);
		System.assertEquals('M1', testSetting.Global_Schedule_Interval__c);
	}   
}