/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, June, 2020
 */
@isTest
public with sharing class GSP_SC_TriggerContext_TEST
{
	@isTest
	private static void test_TriggerContext()
	{
		System.assertEquals(false, GSP_SC_TriggerContext.DisableAllTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableAccountTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableBudgetTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableCaseTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableClinicBudgetTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableLeadTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableEventTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableInvoiceLineTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableOpportunityTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableRevenueScheduleTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableRevenueTargetTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableOpportunityClosedWonTriggers);
		
		GSP_SC_TriggerContext.DisableAllTriggers						= true;
		GSP_SC_TriggerContext.DisableAccountTriggers					= true;
		GSP_SC_TriggerContext.DisableBudgetTriggers						= true;
		GSP_SC_TriggerContext.DisableCaseTriggers						= true;
		GSP_SC_TriggerContext.DisableClinicBudgetTriggers				= true;
		GSP_SC_TriggerContext.DisableEventTriggers						= true;
		GSP_SC_TriggerContext.DisableInvoiceLineTriggers				= true;
		GSP_SC_TriggerContext.DisableLeadTriggers						= true;
		GSP_SC_TriggerContext.DisableOpportunityTriggers				= true;
		GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers		= true;
		GSP_SC_TriggerContext.DisableRevenueScheduleTriggers			= true;
		GSP_SC_TriggerContext.DisableRevenueTargetTriggers				= true;
		GSP_SC_TriggerContext.DisableOpportunityClosedWonTriggers		= true;

		System.assertEquals(true, GSP_SC_TriggerContext.DisableAllTriggers);
		System.assertEquals(true, GSP_SC_TriggerContext.DisableAccountTriggers);
		System.assertEquals(true, GSP_SC_TriggerContext.DisableBudgetTriggers);
		System.assertEquals(true, GSP_SC_TriggerContext.DisableCaseTriggers);
		System.assertEquals(true, GSP_SC_TriggerContext.DisableClinicBudgetTriggers);
		System.assertEquals(true, GSP_SC_TriggerContext.DisableEventTriggers);
		System.assertEquals(true, GSP_SC_TriggerContext.DisableInvoiceLineTriggers);
		System.assertEquals(true, GSP_SC_TriggerContext.DisableLeadTriggers);
		System.assertEquals(true, GSP_SC_TriggerContext.DisableOpportunityTriggers);
		System.assertEquals(true, GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers);
		System.assertEquals(true, GSP_SC_TriggerContext.DisableRevenueScheduleTriggers);
		System.assertEquals(true, GSP_SC_TriggerContext.DisableRevenueTargetTriggers);
		System.assertEquals(true, GSP_SC_TriggerContext.DisableOpportunityClosedWonTriggers);

		GSP_SC_TriggerContext.DisableAllTriggers						= false;
		GSP_SC_TriggerContext.DisableAccountTriggers					= false;
		GSP_SC_TriggerContext.DisableBudgetTriggers						= false;
		GSP_SC_TriggerContext.DisableCaseTriggers						= false;
		GSP_SC_TriggerContext.DisableClinicBudgetTriggers				= false;
		GSP_SC_TriggerContext.DisableEventTriggers						= false;
		GSP_SC_TriggerContext.DisableInvoiceLineTriggers				= false;
		GSP_SC_TriggerContext.DisableLeadTriggers						= false;
		GSP_SC_TriggerContext.DisableOpportunityTriggers				= false;
		GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers		= false;
		GSP_SC_TriggerContext.DisableRevenueScheduleTriggers			= false;
		GSP_SC_TriggerContext.DisableRevenueTargetTriggers				= false;
		GSP_SC_TriggerContext.DisableOpportunityClosedWonTriggers		= false;

		System.assertEquals(false, GSP_SC_TriggerContext.DisableAllTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableAccountTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableBudgetTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableCaseTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableClinicBudgetTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableEventTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableInvoiceLineTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableLeadTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableOpportunityTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableRevenueScheduleTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableRevenueTargetTriggers);
		System.assertEquals(false, GSP_SC_TriggerContext.DisableOpportunityClosedWonTriggers);
	}
}