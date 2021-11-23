global with sharing class SavePatientAndXOFollowController
{
    private String xotrackingRecordTypeId = apexpages.currentpage().getParameters().get('RecordType');//RecordType=012E0000000V3YB
    
    public SavePatientAndXOFollowController(ApexPages.StandardController stdController)
    {
        ThisPatient = new Patient__c();
        Recordtype patientCntRt = [select Id from recordtype where name = 'Patient' and sobjecttype = 'contact'];
        PatientCnt = new Contact(recordtypeid = patientCntRt.Id);
        IsNewClinic = false;
        XOFollowUpTracking = new XO_Follow_Up_Tracking__c();
        if(xotrackingRecordTypeId != null)
        {
            XOFollowUpTracking.RecordTypeId = xotrackingRecordTypeId;  
            String thisRecordTYpeNmae = [select Id, Name from RecordType where SobjectType='XO_Follow_Up_Tracking__c' and Id = :XOFollowUpTracking.RecordTypeId].Name;
            if(thisRecordTYpeNmae == 'Near-site Mountain View')
            {
                IsNewClinic = true;
            }                       
        }
        else
        {        
           Schema.DescribeSObjectResult dsr = XO_Follow_Up_Tracking__c.SObjectType.getDescribe();
           Schema.RecordTypeInfo defaultRecordType;
           for(Schema.RecordTypeInfo rti : dsr.getRecordTypeInfos()) 
           {
                if(rti.isDefaultRecordTypeMapping()) 
                {
                    defaultRecordType = rti;
                }
            }
            if(defaultRecordType.getName() == 'Near-site Mountain View')
            {
                IsNewClinic = true;
            } 
        }       
    }
    
    public SavePatientAndXOFollowController()
    {
        ThisPatient = new Patient__c();
        IsNewClinic = false;
        XOFollowUpTracking = new XO_Follow_Up_Tracking__c();
        if(xotrackingRecordTypeId != null)
        {
            XOFollowUpTracking.RecordTypeId = xotrackingRecordTypeId;  
            String thisRecordTYpeNmae = [select Id, Name from RecordType where SobjectType='XO_Follow_Up_Tracking__c' and Id = :XOFollowUpTracking.RecordTypeId].Name;
            if(thisRecordTYpeNmae == 'Near-site Mountain View')
            {
                IsNewClinic = true;
            }                       
        }
        else
        {        
           Schema.DescribeSObjectResult dsr = XO_Follow_Up_Tracking__c.SObjectType.getDescribe();
           Schema.RecordTypeInfo defaultRecordType;
           for(Schema.RecordTypeInfo rti : dsr.getRecordTypeInfos()) 
           {
                if(rti.isDefaultRecordTypeMapping()) 
                {
                    defaultRecordType = rti;
                }
            }
            if(defaultRecordType.getName() == 'Near-site Mountain View')
            {
                IsNewClinic = true;
            } 
        }        
    }
    
    public Boolean IsNewClinic { get; set; }
    public STring PatientId { get; set; }
    public String DOB { get; set; }
    public String PatientNameSearchword { get; set; }
    public Patient__c ThisPatient { get; set; }
    public Contact PatientCnt { get; set; }
    public XO_Follow_Up_Tracking__c XOFollowUpTracking { get; set; }
    public String ScheudleFollowUpDate { get; set; }
    
    public List<SelectOption> AllXOTrackRecordsTyes
    {
        get
        {
            List<SelectOption> results = new List<SelectOption>();
            for(RecordType rt : [select Id, Name from RecordType where SobjectType='XO_Follow_Up_Tracking__c'])
            {
                results.add(new SelectOption(rt.Id, rt.Name));
            }
            return results;
        }
        set;
    }
    
    @RemoteAction
    global static List<patientInfo> searchPatient(String PatientNameSearchKeyWord)
    {
        List<String> results = new List<STring>();
        List<patientInfo> SearchPatientItems = new List<patientInfo>();
        String keyword = '%' + PatientNameSearchKeyWord + '%';
        for(Contact patient : [select Id, Name, Clinic__c, FirstName, LastName, Birthdate,  Email, Phone, Lumeris_ID__c from Contact where (firstName like: keyword OR Lastname like :keyword or Name like :keyword) and recordtype.name = 'Patient' limit 10000])
        {
            patientInfo patientItem = new patientInfo();
            patientItem.Label = patient.Name;
            patientItem.Firstname = patient.Firstname != null?patient.firstname:'';
            patientItem.Lastname = patient.lastname != null?patient.lastname:'';
            patientItem.Email = patient.Email != null?patient.Email:'';
            patientItem.Phone = patient.Phone != null?patient.Phone:'';
            patientItem.Id = patient.Id;
            patientItem.lumerisid = patient.Lumeris_ID__c != null?patient.Lumeris_ID__c:'';
            String dob = '';
            if(patient.Birthdate != null)
            {//10/22/1995
                dob = (patient.Birthdate.month() >= 10?String.valueOf(patient.Birthdate.month()):('0' + patient.Birthdate.month())) + '/' + (patient.Birthdate.day() >= 10?String.valueOf(patient.Birthdate.day()):('0' + patient.Birthdate.day())) + '/' + String.valueOf(patient.Birthdate.year());
            }
            patientItem.DOB = dob;
            results.add(patientItem.JsonPatientInfo);
            SearchPatientItems.add(patientItem);
        }
        return SearchPatientItems;
    }
    
    public pageReference save()
    {   
        if(PatientId != null && PatientId != '')
        {
            PatientCnt.Id = PatientId;
        } 
        if(DOB != null && DOB != '')
        {
            PatientCnt.Birthdate = date.parse(DOB);
        }
        STring recordTYpeNmae = null;
        if(xotrackingRecordTypeId != null && xotrackingRecordTypeId instanceOf ID)
        {
            recordTYpeNmae = [select Id, Name from RecordType where SobjectType='XO_Follow_Up_Tracking__c' and Id = :XOFollowUpTracking.RecordTypeId].Name;
            PatientCnt.Clinic__c = recordTYpeNmae;
            List<Account> accts = [select Id from Account where Name = :recordTYpeNmae limit 1];
            if(accts.size() > 0)
            {
                PatientCnt.AccountId = accts[0].Id;
            }
        }
        upsert PatientCnt;
        if(ScheudleFollowUpDate != null && ScheudleFollowUpDate != '')
        {
            XOFollowUpTracking.Scheduled_Follow_Up_date__c = date.parse(ScheudleFollowUpDate);
        }
        XOFollowUpTracking.Patient_Contact__c = PatientCnt.Id;
        XOFollowUpTracking.Patient_First_Name__c = PatientCnt.firstname; 
        XOFollowUpTracking.Name = PatientCnt.lastname; 
        XOFollowUpTracking.Patient_DOB__c = PatientCnt.Birthdate;
        XOFollowUpTracking.Lumeris_ID__c = PatientCnt.Lumeris_ID__c; 
        XOFollowUpTracking.Patient_Email__c = PatientCnt.Email; 
        XOFollowUpTracking.Patient_Phone__c = PatientCnt.Phone;
        try
        {
            insert XOFollowUpTracking;
            PageReference retPage = new PageReference('/' + XOFollowUpTracking.Id);
            retPage.setRedirect(true);
            return retPage;
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        return null;
    }
    
    public pageReference saveAndNew()
    {
        if(PatientId != null && PatientId != '')
        {
            PatientCnt.Id = PatientId;
        } 
        if(DOB != null && DOB != '')
        {
            PatientCnt.Birthdate = date.parse(DOB);
        }
        STring recordTYpeNmae = null;
        if(xotrackingRecordTypeId != null && xotrackingRecordTypeId instanceOf ID)
        {
            recordTYpeNmae = [select Id, Name from RecordType where SobjectType='XO_Follow_Up_Tracking__c' and Id = :XOFollowUpTracking.RecordTypeId].Name;
            PatientCnt.Clinic__c = recordTYpeNmae;
        }
        upsert PatientCnt;
        if(ScheudleFollowUpDate != null && ScheudleFollowUpDate != '')
        {
            XOFollowUpTracking.Scheduled_Follow_Up_date__c = date.parse(ScheudleFollowUpDate);
        }
        XOFollowUpTracking.Patient_Contact__c = PatientCnt.Id;
        XOFollowUpTracking.Patient_First_Name__c = PatientCnt.firstname; 
        XOFollowUpTracking.Name = PatientCnt.lastname; 
        XOFollowUpTracking.Patient_DOB__c = PatientCnt.Birthdate;
        XOFollowUpTracking.Lumeris_ID__c = PatientCnt.Lumeris_ID__c; 
        XOFollowUpTracking.Patient_Email__c = PatientCnt.Email; 
        XOFollowUpTracking.Patient_Phone__c = PatientCnt.Phone;
        try
        {
            insert XOFollowUpTracking;
            PageReference retPage = null;
            if(xotrackingRecordTypeId != null)
            {
                retPage = new PageReference('/apex/SavePatientAndXOFollow?RecordType=' + xotrackingRecordTypeId);
            }
            else
            {
                retPage = new PageReference('/apex/SavePatientAndXOFollow');
            }
            retPage.setRedirect(true);
            return retPage;
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        return null;
    }
    
    public pageReference cancel()
    {
        Schema.DescribeSObjectResult r = XO_Follow_Up_Tracking__c.sObjectType.getDescribe();
        String keyPrefix = r.getKeyPrefix();
        PageReference retPage = new PageReference('/' + keyPrefix + '/o');
        retPage.setRedirect(true);
        return retPage;
    }
    
    global class patientInfo
    {
        public patientInfo()
        {
        }
        
        public String Label { get; set; }
        public String Firstname { get; set; }
        public String Lastname { get; set; }
        public String Id { get; set; }
        public String DOB { get; set; }
        public STring lumerisid { get; set; }
        public String Email { get; set; }
        public String Phone { get; set; } 
        
        public String JsonPatientInfo
        {//{id:"101",label:"John Smith",fname:"John",lname:"Smith",dob:"10/22/1995",lumerisid:"L001",email:"john.smith@hotmail.com",phone:"9988776655"},
            get
            {
                String result = '{id:"' + this.Id + '", label:"' + this.Label + '", fname:"' + 
                                    this.FirstName + '",lname:"' + this.Firstname + '",dob:"' + 
                                    this.DOB + '",lumerisid:"' + this.lumerisid + '",email:"' + 
                                    this.Email + '",phone:"' + this.Phone +
                                 '"}';                
                return result;
            }
        }
    }
}