/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, 20 Jul 2020
 */
trigger GSP_SC_Budget on Budget__c (after delete, after insert, after update, before delete, before insert, before update)
{
	if (!GSP_SC_TriggerContext.DisableBudgetTriggers && !GSP_SC_TriggerContext.DisableAllTriggers)
	{
		if (trigger.isBefore)
		{
			if (trigger.isInsert)
			{
				List<Budget__c> budgetList = new List<Budget__c>();
				for (Budget__c budget : trigger.new)
				{
					if ((budget.Account__c == null && budget.Account_Name__c != null) ||
						(budget.Product__c == null && budget.Product_Code_name__c != null))
					{	// Insert from dataloader
						budgetList.add(budget);
					}
				}
				if (!budgetList.isEmpty())
				{
					GSP_SC_trgBudgetMethods.LinkBudgets(budgetList);
				}
				GSP_SC_trgBudgetMethods.SetOwner(trigger.new);
			}
		}
		else
		{
			if (trigger.isInsert)
			{
				GSP_SC_trgBudgetMethods.LinkRevenueSchedules(trigger.new);
			}
		}
	}
}