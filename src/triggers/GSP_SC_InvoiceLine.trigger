/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, 22 Jul 2020
 */
trigger GSP_SC_InvoiceLine on Invoice_Line__c (after delete, after insert, after update, before delete, before insert, before update)
{
	if (!GSP_SC_TriggerContext.DisableInvoiceLineTriggers && !GSP_SC_TriggerContext.DisableAllTriggers)
	{
		if (trigger.isBefore)
		{
			if (trigger.isInsert)
			{
				GSP_SC_trgInvoiceLineMethods.LinkInvoiceLineProducts(trigger.new);
				
			}
		}
		else
		{
			if (trigger.isInsert)
			{
				Set<Id> refIdSet = new Set<Id>();
				Set<Id> accountNameSet = new Set<Id>();
				for (Invoice_Line__c invoiceLine : trigger.new)
				{
					if (!String.isEmpty(invoiceLine.RevId__c))
					{
						refIdSet.add(invoiceLine.Id);
					}
					else if (!String.isEmpty(invoiceLine.Account_Name__c))
					{
						accountNameSet.add(invoiceLine.Id);
					}
					else
					{
						System.assert(false, 'No RevId or Account Name on Invoice Line.');
					}
				}
				if (!refIdSet.isEmpty())
				{
					GSP_SC_trgInvoiceLineMethods.LinkInvoicelineBudgets(refIdSet);
				}
				if (!accountNameSet.isEmpty())
				{
					GSP_SC_trgInvoiceLineMethods.LinkInvoicelineBudgetsByAccountName(accountNameSet);
				}
			}
			else if (trigger.isUpdate)
			{
				Set<Id> invoiceLineSet = new Set<Id>();
				Set<Id> invoiceLineAccountNameSet = new Set<Id>();
				List<Invoice_Line__c> invoiceLineList = new List<Invoice_Line__c>();
				for (Invoice_Line__c invoiceLine : trigger.new)
				{
					Invoice_Line__c oldInvoiceLine = trigger.oldMap.get(invoiceLine.Id);
					if (invoiceLine.RevId__c != oldInvoiceLine.RevId__c ||
						invoiceLine.Accounting_Period__c != oldInvoiceLine.Accounting_Period__c)
					{
						invoiceLineSet.add(invoiceLine.Id);
					}
					else if (invoiceLine.Clinic__c != oldInvoiceLine.Clinic__c)
					{
						invoiceLineAccountNameSet.add(invoiceLine.Id);
					}
					else if (invoiceLine.Amount__c != oldInvoiceLine.Amount__c)
					{
						invoiceLineList.add(invoiceLine);
					}
				}
				
				if (!invoiceLineAccountNameSet.isEmpty())
				{
					GSP_SC_trgInvoiceLineMethods.LinkInvoicelineBudgetsByAccountName(invoiceLineAccountNameSet);
				}
				
				if (!invoiceLineSet.isEmpty())
				{
					GSP_SC_trgInvoiceLineMethods.LinkInvoicelineBudgets(invoiceLineSet);
				}
				if (!invoiceLineList.isEmpty())
				{
					GSP_SC_trgInvoiceLineMethods.RollUpBudgets(invoiceLineList);
				}
			}
			else if (trigger.isDelete)
			{
				GSP_SC_trgInvoiceLineMethods.RollUpBudgets(trigger.old);
			}
		}
	}
}