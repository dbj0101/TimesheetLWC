trigger TimesheetItemTrigger on Timesheet_Item__c (before insert, before update) {
    System.debug('FIRED TimesheetItemTrigger isBefore:'+trigger.isBefore+' isAfter:'+trigger.isAfter+' isInsert:'+trigger.isInsert+' isUpdate:'+trigger.isUpdate);
    
    if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
        if(trigger.isInsert && !trigger.isUpdate) {
            /*
            if(Test.isRunningTest()) {
                System.debug('ISBEFORE INSERT TimesheetItemTrigger isUpdate:'+trigger.isUpdate+' ## isInsert:'+trigger.isInsert);
                for(Timesheet_Item__c ti :trigger.new) {
                    System.debug('Timesheet_Item Trigger ISBEFORE INSERT:'+ti);
                }
            }
			*/
            TimesheetItemTriggerHandler.VerifyNoTimesheetDateDuplicates(trigger.new);
        } 
        else if(trigger.isUpdate) {
            /*
            if(Test.isRunningTest()) {
                System.debug('ISBEFORE UPDATE TimesheetItemTrigger isUpdate:'+trigger.isUpdate+' ## isInsert:'+trigger.isInsert);
                for(Timesheet_Item__c ti :trigger.new) {
                    System.debug('Timesheet_Item Trigger ISBEFORE UPDATE:'+ti);
                }
            }
            */
            for(Timesheet_Item__c ti :trigger.new) {
                if(trigger.oldMap.containsKey(ti.Id)) {
                    if(ti.Logged_Date__c != trigger.oldMap.get(ti.Id).Logged_Date__c) {
                        ti.addError('Cannot alter the Logged Date on Timesheet Item after creation');
                    }
                }
            }
        }
    }//if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate))
}