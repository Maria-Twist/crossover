@isTest
public class testSavePatientAndXOFollowController
{
    @isTest
    static void testController()
    {
        String xoRTypeId = '';
        List<RecordType> rtypes = [select Id, Name from RecordType where SobjectType='XO_Follow_Up_Tracking__c'];
        if(rtypes.size() > 0)
        {
            xoRTypeId = rtypes[0].Id;           
        }
        recordtype patientcntrt = [select Id from Recordtype where name = 'patient' and sobjecttype = 'contact'];
        Contact testPatient = new COntact(recordtypeid = patientcntrt.Id, Email = 'test@test.com', Lumeris_ID__c = '123edswa', firstname = 'david', lastname = 'lee', Phone = '2345643');
        insert testPatient;
        PageReference retPage = new PageReference('/apex/SavePatientAndXOFollow?RecordType=' + xoRTypeId);
        test.setCurrentPage(retPage);
        SavePatientAndXOFollowController controller = new SavePatientAndXOFollowController();
        system.assert(controller.AllXOTrackRecordsTyes != null);
        controller.DOB = '09/23/2015';
        controller.ScheudleFollowUpDate =  '09/23/2015';
        controller.Patientcnt = testPatient;
        controller.XOFollowUpTracking.Reason_For_Follow_Up__c = 'Imaging';
        controller.XOFollowUpTracking.Imaging__c = 'Cardiografix';
        controller.XOFollowUpTracking.Referring_Provider__c = 'Andrea Sullivan, MD';
        SavePatientAndXOFollowController.searchPatient('Da');
        controller.save();
        controller.cancel();
    }
    @isTest
    static void testController2()
    {
        String xoRTypeId = '';
        List<RecordType> rtypes = [select Id, Name from RecordType where SobjectType='XO_Follow_Up_Tracking__c'];
        if(rtypes.size() > 0)
        {
            xoRTypeId = rtypes[0].Id;           
        }
        recordtype patientcntrt = [select Id from Recordtype where name = 'patient' and sobjecttype = 'contact'];
        Contact testPatient = new COntact(recordtypeid = patientcntrt.Id, Email = 'test@test.com', Lumeris_ID__c = '123edswa', firstname = 'david', lastname = 'lee', Phone = '2345643');
        insert testPatient;
        PageReference retPage = new PageReference('/apex/SavePatientAndXOFollow?RecordType=' + xoRTypeId);
        test.setCurrentPage(retPage);
        SavePatientAndXOFollowController controller = new SavePatientAndXOFollowController();
        system.assert(controller.AllXOTrackRecordsTyes != null);
        controller.DOB = '09/23/2015';
        controller.ScheudleFollowUpDate =  '09/23/2015';
        controller.Patientcnt = testPatient;
        controller.saveAndNew();
    }
    
    @isTest
    static void testController3()
    {
        String xoRTypeId = '';
        List<RecordType> rtypes = [select Id, Name from RecordType where SobjectType='XO_Follow_Up_Tracking__c'];
        if(rtypes.size() > 0)
        {
            xoRTypeId = rtypes[0].Id;           
        }
        recordtype patientcntrt = [select Id from Recordtype where name = 'patient' and sobjecttype = 'contact'];
        Contact testPatient = new COntact(recordtypeid = patientcntrt.Id, Email = 'test@test.com', Lumeris_ID__c = '123edswa', firstname = 'david', lastname = 'lee', Phone = '2345643');
        insert testPatient;
        PageReference retPage = new PageReference('/apex/SavePatientAndXOFollow?RecordType=' + xoRTypeId);
        test.setCurrentPage(retPage);
        XO_Follow_Up_Tracking__c xo = new XO_Follow_Up_Tracking__c();
        ApexPages.StandardController stdController = new ApexPages.StandardController(xo);
        SavePatientAndXOFollowController controller = new SavePatientAndXOFollowController(stdController);
        system.assert(controller.AllXOTrackRecordsTyes != null);
        controller.DOB = '09/23/2015';
        controller.ScheudleFollowUpDate =  '09/23/2015';
        controller.Patientcnt = testPatient;
        controller.saveAndNew();
    }
    
    @isTest
    static void testController4()
    {
        String xoRTypeId = '';
        List<RecordType> rtypes = [select Id, Name from RecordType where SobjectType='XO_Follow_Up_Tracking__c'];
        if(rtypes.size() > 0)
        {
            xoRTypeId = rtypes[0].Id;           
        }
        recordtype patientcntrt = [select Id from Recordtype where name = 'patient' and sobjecttype = 'contact'];
        Contact testPatient = new COntact(recordtypeid = patientcntrt.Id, Email = 'test@test.com', Lumeris_ID__c = '123edswa', firstname = 'david', lastname = 'lee', Phone = '2345643');
        insert testPatient;
        PageReference retPage = new PageReference('/apex/SavePatientAndXOFollow');
        test.setCurrentPage(retPage);
        XO_Follow_Up_Tracking__c xo = new XO_Follow_Up_Tracking__c();
        ApexPages.StandardController stdController = new ApexPages.StandardController(xo);
        SavePatientAndXOFollowController controller = new SavePatientAndXOFollowController(stdController);
        system.assert(controller.AllXOTrackRecordsTyes != null);
        controller.DOB = '09/23/2015';
        controller.ScheudleFollowUpDate =  '09/23/2015';
        controller.Patientcnt = testPatient;
        controller.XOFollowUpTracking.Reason_For_Follow_Up__c = 'Imaging';
        controller.XOFollowUpTracking.Imaging__c = 'Cardiografix';
        controller.XOFollowUpTracking.Referring_Provider__c = 'Andrea Sullivan, MD';
        SavePatientAndXOFollowController.searchPatient('Da');
        controller.save();
        controller.cancel();
    }
}