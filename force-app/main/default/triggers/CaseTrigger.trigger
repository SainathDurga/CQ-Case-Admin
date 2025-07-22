trigger CaseTrigger on Case (after insert, after update) {
    if(Trigger.isAfter){
        if(Trigger.isInsert || Trigger.isUpdate){
            CaseTriggerHandler.handleNonconformanceEscalation(Trigger.new);
        }
    }
}