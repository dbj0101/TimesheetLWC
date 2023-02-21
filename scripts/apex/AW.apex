/*
string sJson = '[{"timesheetId":"a037e00000685ZcAAI","projectName":"projectName","day1":{"idValue":"a027e000005REtlAAG","dataValue":"1:00"},"day2":{"idValue":"a027e000005REtmAAG","dataValue":"1:00"},"day3":{"idValue":"a027e000005REtnAAG","dataValue":"1:00"},"day4":{"idValue":"a027e000005REtoAAG","dataValue":"1:00"},"day5":{"idValue":"a027e000005REtpAAG","dataValue":"1:00"},"day6":{"idValue":"a027e000005REtqAAG","dataValue":"1:00"},"day7":{"idValue":"a027e000005REtrAAG","dataValue":"1:00"}},{"timesheetId":"a037e00000688VhAAI","projectName":"projectName","day1":{"idValue":"a027e000005RLrvAAG","dataValue":"2:00"},"day2":{"idValue":"a027e000005RLrwAAG","dataValue":"2:00"},"day3":{"idValue":"a027e000005RLrxAAG","dataValue":"2:00"},"day4":{"idValue":"a027e000005RLryAAG","dataValue":"2:00"},"day5":{"idValue":"a027e000005RLrzAAG","dataValue":"2:00"},"day6":{"idValue":"a027e000005RLs0AAG","dataValue":"2:00"},"day7":{"idValue":"a027e000005RLs1AAG","dataValue":"2:00"}}]';
//TimeSheetComponentController.TimesheetItem
List<TimeSheetComponentController.TimesheetItem> listObj=(List<TimeSheetComponentController.TimesheetItem>) JSON.deserializeStrict(sJson, List<TimeSheetComponentController.TimesheetItem>.class);

System.debug(listObj);
*/

Date dt =  date.today();
system.debug('year:'+dt.year());
system.debug('month:'+dt.month());
system.debug('day:'+dt.day());