trigger TimesheetTrigger on Timesheet__c (after insert, before insert, before update) {
    if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate))  {
        //check Timesheet for duplicate Project,Week Combinations
        //First get list of timesheets that need checked
        List<Timesheet__c> listTimesheetDupeCheck = new List<Timesheet__c>();
        if(trigger.isUpdate) {
            //only  get ones where Member, WeekStart, or Project changed
            for(Timesheet__c ts :trigger.new) {
                Timesheet__c tsComp = trigger.oldMap.get(ts.Id);
                if (ts.Member__c != tsComp.Member__c || ts.Date_Week_Start__c != tsComp.Date_Week_Start__c || ts.Project__c!=tsComp.Project__c) {
                    listTimesheetDupeCheck.add(ts);
                }
            }
        }//if(trigger.isUpdate)
        else if(trigger.isInsert) {
            for(Timesheet__c ts :trigger.new) {
                listTimesheetDupeCheck.add(ts);
            }
        }
        //continue only if there are items to check
        if(listTimesheetDupeCheck.size()>0) {
            //Map all potential dupes by date
            Map<date, List<Timesheet__c>> MapDateWeekToListTimesheet = new Map<date, List<Timesheet__c>>();
            Set<date> setDateWeek = new Set<date>();
            Set<Id> setUserId = new Set<Id>();
            Set<Id> setProjectId = new Set<Id>();
            for(Timesheet__c ts :Trigger.new) {
                setDateWeek.add(ts.Date_Week_Start__c);
                setUserId.add(ts.Member__c);
                setProjectId.add(ts.Project__c);
            }
            //Start the list
            for(Date d :setDateWeek) {
                MapDateWeekToListTimesheet.put(d, new List<Timesheet__c>());
            }
            for(Timesheet__c ts :[select Id, Name, Project__c, Date_Week_Start__c, Member__c 
                                  from Timesheet__c
                                  where Date_Week_Start__c in :setDateWeek
                                  and Member__c in :setUserId
               					  and Project__c in :setProjectId])
            {
                MapDateWeekToListTimesheet.get(ts.Date_Week_Start__c).add(ts);
            }
            for(Timesheet__c ts :Trigger.new) {
                Boolean bErrorAdded=false;
                System.debug('COMPARE  ts:'+ts);
                for (Timesheet__c tsComp :MapDateWeekToListTimesheet.get(ts.Date_Week_Start__c)) {
                    System.debug('TO tsComp:'+tsComp);
                    System.debug('TO ts.Project__c==tsComp.Project__c:'+(ts.Project__c==tsComp.Project__c)+' ## ts.Member__c==tsComp.Member__c:'+(ts.Member__c==tsComp.Member__c)+' ## (ts.Id!=tsComp.Id  || !(ts.Id!=null)):'+(ts.Id!=tsComp.Id  || !(ts.Id==null)));
                    if(ts.Project__c==tsComp.Project__c && ts.Member__c==tsComp.Member__c && (ts.Id!=tsComp.Id  || !(ts.Id!=null))) {
                        System.debug('DUPE ERROR ADDED');
                        //dupe value
                        ts.addError('Duplicate timesheet cannot be added or saved');
                        bErrorAdded = true;
                        break;
                    }
                }
                if (!bErrorAdded) {
                    MapDateWeekToListTimesheet.get(ts.Date_Week_Start__c).add(ts); 
                }
            }
        }//if(listTimesheetDupeCheck.size()>0)
        
        
    }
    if(trigger.IsAfter && trigger.IsInsert) {
        List<Timesheet_Item__c> listTeInsert = new List<Timesheet_Item__c>();
        for(Timesheet__c t :trigger.new) {
            for(integer i=0; i<7; i++) {
                Timesheet_Item__c ti = new Timesheet_Item__c();
                ti.Timesheet__c = t.Id;
                Date d = t.Date_Week_Start__c;
                ti.Logged_Date__c = d.addDays(i);
                //ti.Hours__c = 0;
                ti.Hours_Text__c = '0:00';
                listTeInsert.add(ti);
            }
        }
        
        if(listTeInsert.size()>0) {
            insert(listTeInsert);
        }
    }
}