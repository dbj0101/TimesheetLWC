public with sharing class TimeSheetReportingController {
    public TimeSheetReportingController() {

    }

    public static string GetCurrentHoursData1() {
        string sRet = '';
        sRet = sRet+'{ "dataPie":[40, 62, 85], "labelPie":["Project One", "Project Two", "Project Three"], "colorPie":["#f00", "#0f0", "#00f"]';
        sRet = sRet+' ,"dataBar":[22, 18], "labelBar":["Project Two", "Project Three"], "colorBar":["#0f0", "#00f"]';
        sREt = sRet+' }';
        return 'hello';
    }

    @AuraEnabled
    public static string GetCurrentHoursData() {//'0057e00000RluVtAAJ' 
        string userId='0057e00000RluVtAAJ';
        string sRet = '';
        set<date> setDates = new set<date>();
        date firstMonday = TimeSheetComponentController.getWeekStartDate(Date.today().year(), Date.today().month(), Date.today().day());
        setDates.add(firstMonday);
        //get monday dates from last 3 months
        for(integer i=1; i<=12; i++) {
            setDates.add(firstMonday.addDays((-7) * i));
        }
        for(date d :setDates) { System.debug('setDates '+d); }
        AggregateResult[] aggRes3Month = [select Project__c, Project__r.Name, sum(Total_Minutes__c) 
                                           from Timesheet__c where Member__c=:userId
                                           and Date_Week_Start__c in :setDates 
                                           group by Project__c, Project__r.Name];
        AggregateResult[] aggResCurrentWeek = [select Project__c, Project__r.Name, sum(Total_Minutes__c) 
                                                from Timesheet__c where Member__c=:userId
                                                and Date_Week_Start__c=:firstMonday 
                                                group by Project__c, Project__r.Name];
        ReportData rd = new ReportData();
        for(AggregateResult agg :aggRes3Month) {
            Decimal hrs = Decimal.valueOf(String.valueOf(agg.get('expr0')))/60.00;
            hrs = hrs.setScale(2);
            rd.dataPie.add(hrs);
            rd.labelPie.add(String.valueOf(agg.get('Name')));
            rd.colorPie.add(GetRandomColor());
        }
        for(AggregateResult agg :aggResCurrentWeek) {
            Decimal hrs = Decimal.valueOf(String.valueOf(agg.get('expr0')))/60.00;
            hrs = hrs.setScale(2);
            rd.dataBar.add(hrs);
            rd.labelBar.add(String.valueOf(agg.get('Name')));
            rd.colorBar.add(GetRandomColor());
        }
        System.debug('rd:'+rd);
        sRet = JSON.serialize(rd);
        return sRet;
    }
    
    public static string GetRandomColor() {
        //added a second f because the final item in list never showed up in several tests
        List<string> lHex = new List<string> {'0','1','2','3','4','5','6','7','8','9','a','b','c','e','f','f'};
        integer rand1 = (Math.random() *(lHex.size()-1)).intValue();
        integer rand2 = (Math.random() *(lHex.size()-1)).intValue();
        integer rand3 = (Math.random() *(lHex.size()-1)).intValue();
        integer rand4 = (Math.random() *(lHex.size()-1)).intValue();
        integer rand5 = (Math.random() *(lHex.size()-1)).intValue();
        integer rand6 = (Math.random() *(lHex.size()-1)).intValue();
        return '#'+lHex[rand1]+lHex[rand2]+lHex[rand3]+lHex[rand4]+lHex[rand5]+lHex[rand6];
    }
    
    public class ReportData {
        List<Decimal> dataPie;
        List<String> labelPie;
        List<String> colorPie;
        List<Decimal> dataBar;
        List<String> labelBar;
        List<String> colorBar;
        
        public ReportData() {
            dataPie = new List<Decimal>();
            labelPie = new List<String>();
            colorPie = new List<String>();
            dataBar = new List<Decimal>();
            labelBar = new List<String>();
            colorBar = new List<String>();
        }
    }
}