/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, June, 2020
 */
trigger GSP_SC_RevenueSchedule on Revenue_Schedule__c (after delete, after insert, after update, before delete, before insert, before update)
{
    if (!GSP_SC_TriggerContext.DisableRevenueScheduleTriggers && !GSP_SC_TriggerContext.DisableAllTriggers)
    {
        if (trigger.isBefore)
        {
            
        }
        else
        {
            List<Revenue_Schedule__c> revenueScheduleList = new List<Revenue_Schedule__c>();
            List<Revenue_Schedule__c> revenueScheduleForecastList = new List<Revenue_Schedule__c>();

            if (trigger.isInsert || trigger.isDelete)
            {
                if (trigger.isDelete)
                {
                	GSP_SC_trgRevenueScheduleMethods.UpdateTargetsOnDelete(trigger.old);
                }
                else if (trigger.isInsert)
                {
                	// ACM Roll Ups
					GSP_SC_trgRevenueScheduleMethods.UpdateOpportunityRollUpFields(trigger.new);
                }
            }
            else if (trigger.isUpdate)
            {
                for (Revenue_Schedule__c revenueSchedule : trigger.new)
                {
                	Revenue_Schedule__c oldRevenueSchedule = trigger.oldmap.get(revenueSchedule.Id);
                	if (revenueSchedule.Revenue_Amount__c != oldRevenueSchedule.Revenue_Amount__c ||
                		revenueSchedule.Actual__c != oldRevenueSchedule.Actual__c)
                	{
                		revenueScheduleList.add(revenueSchedule);
                	}
                	if (revenueSchedule.Latest_Forecast__c != oldRevenueSchedule.Latest_Forecast__c ||
                		revenueSchedule.Revenue_Amount__c != oldRevenueSchedule.Revenue_Amount__c)
                	{
                		revenueScheduleForecastList.add(revenueSchedule);
                	}
                }
            }
            
            if (!revenueScheduleList.isEmpty())
            {
            	GSP_SC_trgRevenueScheduleMethods.UpdateOpportunityLineItemValues(revenueScheduleList);
            }
            
            if (!revenueScheduleForecastList.isEmpty())
            {
            	GSP_SC_trgRevenueScheduleMethods.UpdateOpportunityRollUpFields(revenueScheduleForecastList);
            }
        }
    }  
}