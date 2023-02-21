@isTest
public class Test_TimeSheetReportingController {
    
    @isTest
    public static void TestReporting() {
        Project__c prj = TestDataFactory.createProject('Test Project');
        insert prj;
        Project_Member__c prjm = TestDataFactory.createProjectMember(prj);
        insert prjm;
        Timesheet__c ts = TestDataFactory.createTimesheet(prjm);
        ts.Date_Week_Start__c = TestDataFactory.getWeekStartDate(-1);
        insert ts;
        System.debug('Test_TimeSheetReportingController.TestReporting project:'+prj);
        List<Timesheet_Item__c> listTsi = [select Id, Name from Timesheet_Item__c where Timesheet__c=:ts.Id];
        System.assertEquals(listTsi.size(), 7, 'Seven timesheet items are expected to be created from TimesheetTrigger');
    }
}
