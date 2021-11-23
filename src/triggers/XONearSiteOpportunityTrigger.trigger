trigger XONearSiteOpportunityTrigger on Opportunity (
	before insert, after insert,
	before update, after update) {

	String nearSiteOppoTypeId =
		(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().containsKey('Near-Site')) ?
		(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Near-Site').getRecordTypeId()) :
		null;

	if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
		List<Opportunity> opposToUpdate = new List<Opportunity>();

		for (Opportunity oppo : (Trigger.new)) {
			if (oppo.RecordTypeId == nearSiteOppoTypeId && oppo.Amount != oppo.Committed_Monthly_Value__c) {
				Opportunity cloneOppo = oppo.clone(true);
				cloneOppo.Amount = cloneOppo.Committed_Monthly_Value__c;
				opposToUpdate.add(cloneOppo);
			}
		}

		update opposToUpdate;
	}

}