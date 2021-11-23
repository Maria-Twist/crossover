/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, 20 Jul 2020
 */
trigger GSP_SC_ClinicBudget on Clinic_Budget__c (after delete, after insert, after undelete, after update, before delete, before insert, before update)
{
    if (!GSP_SC_TriggerContext.DisableClinicBudgetTriggers && !GSP_SC_TriggerContext.DisableAllTriggers)
	{
		if (trigger.isBefore)
		{
			
		}
		else
		{
			if (trigger.isInsert)
			{
				GSP_SC_trgClinicBudgetMethods.LinkLineItemsAndSchedules(trigger.new);
			}			
		}
	}
}