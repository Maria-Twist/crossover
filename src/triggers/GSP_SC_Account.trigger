/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, 21 Jul 2020
 */
trigger GSP_SC_Account on Account (after delete, after insert, after update, before delete, before insert, before update)
{
	if (!GSP_SC_TriggerContext.DisableAccountTriggers && !GSP_SC_TriggerContext.DisableAllTriggers)
	{
		if (trigger.isbefore)
		{
			
		}
		else
		{
			if (trigger.isUpdate)
			{
				Set<Id> accountSet = new Set<Id>();
				Map<Id, Id> oldOwnerMap = new Map<Id, Id>();
				for (Account account : trigger.new)
				{
					Account oldAccount = trigger.oldMap.get(account.Id);
					if (account.Ownerid != oldAccount.OwnerId)
					{
						oldOwnerMap.put(account.Id, oldAccount.OwnerId);
						accountSet.add(account.Id);
					}
				}
				
				if (!accountSet.isEmpty())
				{
					GSP_SC_trgAccountMethods.UpdateScheduleAccountOwners(accountSet, oldOwnerMap);
				}
			}
		}
	}
}