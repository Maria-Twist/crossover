/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, 21 Jul 2020
 */
 @isTest
private class GSP_SC_BudgetHelper_TEST
{
	@isTest
	public static void testConverter() 
	{
		GSP_SC_BudgetHelper.currencyMap.put('EUR', 1.5);
		GSP_SC_BudgetHelper.currencyMap.put('GBP', 1.0);
		System.assertEquals(1500, GSP_SC_BudgetHelper.ConvertCurrency(1000, 'GBP', 'EUR'));
	} 
}