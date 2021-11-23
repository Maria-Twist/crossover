public with sharing class XONearSiteAccountTriggerHandler {

	private List<ITriggerHandler> handlers;
	private List<Account> newValues;
	private List<Account> oldValues;

	public static String nearSiteOppoTypeId =
		(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().containsKey('Near-Site')) ?
		(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Near-Site').getRecordTypeId()) :
		null;

	public XONearSiteAccountTriggerHandler(
		List<ITriggerHandler> handlers,
		List<Account> newValues,
		List<Account> oldValues) {

		this.handlers = handlers;
		this.newValues = newValues;
		this.oldValues = oldValues;
	}

	public void execute() {
		for (ITriggerHandler handler : this.handlers) {
			handler.execute(this.newValues, this.oldValues);
		}
	}

	public class NearSiteLivesCalculator implements ITriggerHandler {

		public void execute(List<Account> newValues, List<Account> oldValues) {
			if (newValues == null
				|| XONearSiteAccountTriggerHandler.nearSiteOppoTypeId == null) {

				return;
			}

			Map<Id, Opportunity> opposToUpdate = new Map<Id, Opportunity>();

			List<Id> oppoIds = new List<Id>();
			for (Account acc : newValues) {
					oppoIds.add(acc.Near_Site_Opportunity__c);
			}

			List<Opportunity> committedOppos = [
				SELECT
				(
					SELECT Number_of_Lives__c
					FROM NearSiteAccounts__r
					WHERE Probability__c = 100
						AND Number_of_Lives__c != null
				)
				FROM Opportunity
				WHERE Id IN :oppoIds
					AND RecordTypeId = :XONearSiteAccountTriggerHandler.nearSiteOppoTypeId
			];
			for (Opportunity opp : committedOppos) {
				Decimal lives = 0;
				for (Account nsAcc : opp.NearSiteAccounts__r) {
					lives += nsAcc.Number_of_Lives__c;
				}

				if (!opposToUpdate.containsKey(opp.Id)) {
					opp.Committed_Lives__c = lives;
					opposToUpdate.put(opp.Id, opp);
				}
				else {
					opposToUpdate.get(opp.Id).Committed_Lives__c = lives;
				}
			}

			List<Opportunity> totalLivesOppos = [
				SELECT
				(
					SELECT Number_of_Lives__c
					FROM NearSiteAccounts__r
					WHERE Number_of_Lives__c != null
				)
				FROM Opportunity
				WHERE Id IN :oppoIds
					AND RecordTypeId = :XONearSiteAccountTriggerHandler.nearSiteOppoTypeId
			];
			for (Opportunity opp : totalLivesOppos) {
				Decimal lives = 0;
				for (Account nsAcc : opp.NearSiteAccounts__r) {
					lives += nsAcc.Number_of_Lives__c;
				}

				if (!opposToUpdate.containsKey(opp.Id)) {
					opp.Potential_Lives__c = lives;
					opposToUpdate.put(opp.Id, opp);
				}
				else {
					opposToUpdate.get(opp.Id).Potential_Lives__c = lives;
				}
			}

			List<Opportunity> weightedLivesOppos = [
				SELECT
				(
					SELECT Weighted_Number_of_Lives__c
					FROM NearSiteAccounts__r
					WHERE Weighted_Number_of_Lives__c != null
				)
				FROM Opportunity
				WHERE Id IN :oppoIds
					AND RecordTypeId = :XONearSiteAccountTriggerHandler.nearSiteOppoTypeId
			];
			for (Opportunity opp : weightedLivesOppos) {
				Decimal lives = 0;
				for (Account nsAcc : opp.NearSiteAccounts__r) {
					lives += nsAcc.Weighted_Number_of_Lives__c;
				}

				if (!opposToUpdate.containsKey(opp.Id)) {
					opp.Weighted_Number_of_Lives__c = lives;
					opposToUpdate.put(opp.Id, opp);
				}
				else {
					opposToUpdate.get(opp.Id).Weighted_Number_of_Lives__c = lives;
				}
			}

			update opposToUpdate.values();
		}

	}

}