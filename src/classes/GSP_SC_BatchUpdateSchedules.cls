/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, June, 2020
 */
global without sharing class GSP_SC_BatchUpdateSchedules implements Database.Batchable<sObject>
{
	global String strQuery;
	global String projectionType;
    
    global GSP_SC_BatchUpdateSchedules(String strProjectionType)
	{
		this.projectionType = strProjectionType;
		strQuery = 'SELECT Id From OpportunityLineItem WHERE HasSchedule = true';
		if (Test.isRunningTest())
		{
			strQuery += ' LIMIT 1';
		}
	}
	
	global GSP_SC_BatchUpdateSchedules(Id opportunityLineItemId)
	{
		this.projectionType = 'Straight Line';
		strQuery = 'SELECT Id From OpportunityLineItem WHERE Id = \'' + opportunityLineItemId + '\' LIMIT 1';
	}
	
	global Database.QueryLocator start(Database.BatchableContext batchableContext)
	{
		return Database.getQueryLocator(strQuery);
	}
	
	global void execute(Database.BatchableContext batchableContext, List<OpportunityLineItem> scope)
	{
		GSP_SC_ScheduleHelper.BatchUpdateSalesforceSchedules(scope, this.projectionType);
	}
	
	global void finish(Database.BatchableContext batchableContext)
	{
	}
}