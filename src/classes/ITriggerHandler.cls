public interface ITriggerHandler {

	void execute(List<SObject> newValues, List<SObject> oldValues);

}