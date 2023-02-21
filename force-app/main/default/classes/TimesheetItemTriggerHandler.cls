public class TimesheetItemTriggerHandler {
    public static void VerifyNoTimesheetDateDuplicates(List<Timesheet_Item__c> listItemsToVerify) {
        //First get all the timesheets we are working with
        Set<Id> setTimesheetId = new Set<Id>();
        for(Timesheet_Item__c tsi :listItemsToVerify) {
            if(!setTimesheetId.contains(tsi.Timesheet__c)) {
                setTimesheetId.add(tsi.Timesheet__c);
            }
        }
        //Get a list of all Dates already added for each Timesheet
        Map<Id, Map<Date, Id>> mapTimesheetIdToMapDateToItemId = new Map<Id, Map<Date, Id>>();
        for(Timesheet_Item__c tItem :[select Id, Name, Logged_Date__c, Timesheet__c from Timesheet_Item__c where Timesheet__c in :setTimesheetId]){
            if(!mapTimesheetIdToMapDateToItemId.containsKey(tItem.Timesheet__c)) {
                Map<Date, Id> mapDateToItemId = new Map<Date, Id>();
                mapDateToItemId.put(tItem.Logged_Date__c, tItem.Id);
                mapTimesheetIdToMapDateToItemId.put(tItem.Timesheet__c, mapDateToItemId);
            }
            else {
                mapTimesheetIdToMapDateToItemId.get(tItem.Timesheet__c).put(tItem.Logged_Date__c, tItem.Id);
            }
        }
        //Report some output if a TEST is running
        if(Test.isRunningTest()) {
            for(Id tsId :mapTimesheetIdToMapDateToItemId.keySet()) {
                System.debug('TimesheetItemTriggerHandler.VerifyNoTimesheetDateDuplicates() -- mapTimesheetIdToMapDateToItemId ITEM');
                System.debug('tsId:'+tsId+' '+mapTimesheetIdToMapDateToItemId.get(tsId).keySet());
            }
        }
        //Check if anything in listItemsToVerify already exist
        if(mapTimesheetIdToMapDateToItemId.size()>0) {
            for(Timesheet_Item__c tItem :listItemsToVerify) {
                if(mapTimesheetIdToMapDateToItemId.containsKey(tItem.Timesheet__c)) {
                    if(mapTimesheetIdToMapDateToItemId.get(tItem.Timesheet__c).containsKey(tItem.Logged_Date__c)) {
                        tItem.addError('Logged Date has already been added to the Timesheet');
                    } 
                    else {
                        //Add this Date to the Item List so two duplicates gets turned down
                        mapTimesheetIdToMapDateToItemId.get(tItem.Timesheet__c).put(tItem.Logged_Date__c, tItem.Id);
                    }
                } //if(mapTimesheetIdToMapDateToItemId.containsKey(tItem.Timesheet__c))
            } //for(Timesheet_Item__c tItem :listItemsToVerify)
        } //if(mapTimesheetIdToMapDateToItemId.size()>0)
        //trigger.new[0].addError('Cannot insert duplicate Date Logged field');
    }
}