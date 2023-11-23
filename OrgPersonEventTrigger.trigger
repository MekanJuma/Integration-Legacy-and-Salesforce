trigger OrgPersonEventTrigger on OrgPersonEvent__e (after insert) {
    
    Trigger_Settings__c settings = Trigger_Settings__c.getOrgDefaults();
    if (settings != null && settings.Is_Trigger_Active__c) {
        OrgPersonEventProcessor processor = new OrgPersonEventProcessor(Trigger.new);
    	processor.process();
    }
    
}