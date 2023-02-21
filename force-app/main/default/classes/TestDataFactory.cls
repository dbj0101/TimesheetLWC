@isTest
public class TestDataFactory {
    public static Project__c createProject(string projName) {
        Project__c proj =  new  Project__c();
        proj.Name = projName;
        proj.Status__c='Not Started';
        return proj;
    }
    
    public static Project_Member__c createProjectMember(Project__c proj){
        Project_Member__c pm = new Project_Member__c();
        pm.Member__c  = userInfo.getUserId();
        pm.Project__c = proj.Id;
        return pm;
    }
    
    public static Timesheet__c createTimesheet(Project_Member__c pm) {
        Date dt = Date.today();
        dt = TimeSheetComponentController.getWeekStartDate(dt.year(), dt.month(), dt.day());
        Timesheet__c ts = new Timesheet__c();
        ts.Project__c=pm.Project__c; //proj.Id;
        ts.Member__c=pm.Member__c;
        ts.Date_Week_Start__c=dt;
        return ts;
    }
    
    public static Date getWeekStartDate(integer addWeeks) {
        Date today = Date.today();
        if(today==today.toStartOfWeek()) {
            today = today.addDays(-1);
        }
        today = today.addDays(addWeeks * 7);
        return today.toStartOfWeek().addDays(1);
    }
}