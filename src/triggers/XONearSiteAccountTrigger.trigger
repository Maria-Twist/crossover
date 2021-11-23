trigger XONearSiteAccountTrigger on Account (
	before insert, after insert,
	before update, after update,
	before delete, after delete) {

	XONearSiteAccountTriggerHandler handlerContainer;

	if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
		handlerContainer = new XONearSiteAccountTriggerHandler(
			new List<ITriggerHandler> {
				new XONearSiteAccountTriggerHandler.NearSiteLivesCalculator()
			},
			(Trigger.new),
			(Trigger.old)
		);
	}
	if (Trigger.isAfter && Trigger.isDelete) {
		handlerContainer = new XONearSiteAccountTriggerHandler(
			new List<ITriggerHandler> {
				new XONearSiteAccountTriggerHandler.NearSiteLivesCalculator()
			},
			(Trigger.old),
			null
		);
	}

	if (handlerContainer != null) {
		handlerContainer.execute();
	}

}