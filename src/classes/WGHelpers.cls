public without sharing class WGHelpers {

    private static boolean Auth = false;

    // Strip all punctuation from phone number if it is 10 digits
    public static String formatphonenumber(String cphone) {
        String fphone = cphone.replaceAll('\\D', '');

        if (fphone.length() == 10) {
            // fphone = formatphonenum(fphone);
            return fphone;
        } else {
            return cphone;
        }

    }

    static String formatphonenum(String s) {
        s = '(' + s.substring(0, 3) + ') ' + s.substring(3, 6) + '-' + s.substring(6);
        return s;
    }

    public static List<String> getIndivContribTypes() {
        List<string> IndivContribTypes = new List<string>();
        List<IndividualContribTypes__mdt> icts = IndividualContribTypes__mdt.getall().values();
        system.debug('icts is ' + icts);
        For (IndividualContribTypes__mdt ict : icts) {
            system.debug('ict is ' + ict);
            if (String.ISNOTBLANK(ict.Label)) {
                // system.debug('ict.Label is ' + ict.Label + ' and IndivContribTypes is ' + IndivContribTypes);
                IndivContribTypes.add(ict.Label);
                system.debug('IndivContribTypes is now ' + IndivContribTypes);
            }
        }
        system.debug('WGHelpers.getIndivContribTypes returns ' + IndivContribTypes);
        return IndivContribTypes;
    }

// Retrieve our namespace.  Returns Null or the namespace without any adornment.
// From https://salesforce.stackexchange.com/questions/5734/determine-the-apex-classs-namespace 
// I query for WGHelpers because it will be here if this test is installed.
    public static String getNamespace() {
        ApexClass ac = [
                SELECT NameSpacePrefix
                FROM ApexClass
                WHERE Name = 'WGHelpers'
        ];
        string NameSpaceString = ac.NameSpacePrefix;
        return NameSpaceString;
    }

// Retrieve time offset for the current user.
    public static integer getoffset() {
        integer result;
        TimeZone tz = UserInfo.getTimeZone();
        //Milliseconds to Day
        result = tz.getOffset(DateTime.now()) / (1000 * 3600);
        return result;
    }

    public static Id getUnknownCampaignId() {
        Campaign UnknownCampaign;
        if (UnknownCampaign == null) {
            try {
                UnknownCampaign = [SELECT Id FROM Campaign WHERE Name = 'Unknown Campaign' LIMIT 1];
            } catch (QueryException e) {
                if (e.getMessage() == 'List has no rows for assignment to SObject') {
                    UnknownCampaign = new Campaign(
                            Name = 'Unknown Campaign',
                            // Assumes recordType defaults to Fundraising Activity
                            Description = ('Created on ' + String.valueOf(System.now().date()) + ' to handle contribution without campaign.  All contributions without campaigns are sent here.'),
                            IsActive = true
                    );
                    insert UnknownCampaign;
                }
            }
        }
        return UnknownCampaign.Id;
    }

    private static List<CampaignStatiMDT__mdt> CampaignStatiMDT;

    public static List<CampaignStatiMDT__mdt> getCampaignStatiMDT() {
        if (CampaignStatiMDT == null) {
            string querystring = 'select ';
            List<String> types = new String[]{
                    'CampaignStatiMDT__mdt'
            };
            DescribeSObjectResult[] results = Schema.describeSObjects(types);
            System.debug('Got describe information for ' + results.size() + ' sObjects.');
            for (Schema.DescribeSobjectResult res : results) {
                Map<String, Schema.SObjectField> fieldsMap = res.fields.getMap();
                system.debug('Fields are ' + fieldsMap.keySet());
                For (string s : fieldsMap.keyset()) {
                    querystring += s + ', ';
                }
                querystring = querystring.LEFT(querystring.length() - 2) + ' from CampaignStatiMDT__mdt';
                CampaignStatiMDT = Database.query(querystring);
            }
        }
        RETURN CampaignStatiMDT;
    }
/*
    public static Boolean returnAuth() {
        return Auth;
    }
    public static Boolean setAuth(){
        List<WG_Settings__c> RA = [select ReturnAuth__c, LastModifiedDate from WG_Settings__c where name = 'newsletter'];
        system.debug('RA is ' + RA[0].ReturnAuth__c + ' and it was last modified on ' + RA[0].LastModifiedDate);
        If (RA[0].LastModifiedDate<system.today()) {
            List<User> LU = [
                    select email, name, isActive
                    from User
                    where
                    email = 'baird@watergrass.org' or email = 'support@watergrass.org'
            ];
            system.debug('List of users is ' + LU);
            RA[0].ReturnAuth__c = LU.size() < 1 ? false : true;
            Auth = RA[0].ReturnAuth__c;
            update RA[0];
            system.debug('ReturnAuth__c updated to ' + [select ReturnAuth__c, LastModifiedDate from WG_Settings__c where name = 'newsletter']);
        }
        return RA[0].ReturnAuth__c;
    }
    */
    public static List<SelectOption> getPicklistEntries(String sobjstring, String Fldname) {
        List<SelectOption> PEs = new List<SelectOption>();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SobjectType oType = gd.get(sobjstring);
        Schema.DescribeSObjectResult sObjResult = oType.getDescribe();
        Map<String, Schema.SObjectField> sObjFields = sObjResult.fields.getMap();
        List<Schema.PicklistEntry> picklistValues = sObjFields.get(Fldname).getDescribe().getPicklistValues();
        for (Schema.PicklistEntry entry : picklistValues) {
            PEs.add(new SelectOption(entry.getLabel(), entry.getValue()));
        }
        return PEs;
    }

    public static string getSitioBaseURL() {
        // List<string> results = new List<String>();
        Site Sitio;
        string SitioJSON;
        string BaseUrl;
        Try {
            Sitio = [select MasterLabel, Name, Status, Subdomain, Description, UrlPathPrefix, GuestUserId from Site where MasterLabel = :'Signup' LIMIT 1];
            String path = '/sites/servlet.SiteDebugMode';
            PageReference pr = new PageReference(path);
            pr.getParameters().put('guid', Sitio.GuestUserId);
            pr.getParameters().put('sitedebugmode', 'x');
            if (Test.isRunningTest()) {
                BaseURL = 'BaseURL';
            } else {
                BaseUrl = pr.getContent().toString().substringAfter('URL=').substringBefore(path);
                system.debug('In controller, BaseURL is calculated to be ' + BaseURL);
            }
        } catch (QueryException e) {
            System.debug(e.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'Sorry, cannot find the site named Signup, which is required for WG signup pages.  Please go to Setup / Sites and rename your default site to Signup.'));
        }
        return BaseURL;
    }

    public static String getVolToken() {
        Datetime dt = system.now();
        String s = string.valueof(dt);
        String s2 = s.replaceAll('\\D', '');
        String s3 = userinfo.getOrganizationId() + s2;
        Blob s3Blob = Blob.valueOf(s3);
        String sMyToken = 'X123';
        Blob cipherText = Crypto.encryptWithManagedIV('AES256', s3Blob, Blob.valueOf(sMyToken));
        String encodedCipherText = EncodingUtil.convertToHex(cipherText);
        String sFinalToken = EncodingUtil.urlEncode(encodedCipherText, 'UTF-8') ;
        return sFinalToken;
    }

    public static string getBaseURL() {
        string OrgID18 = [select id from Organization].Id;
        string BaseURL;

        Try {
            Site Sitio = [select MasterLabel, Name, Status, Subdomain, Description, UrlPathPrefix, GuestUserId from Site where MasterLabel = :'Signup' LIMIT 1];
            If (Sitio == null) ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'Sorry, cannot find the site named Signup, which is required for WG signup pages.  Please go to Setup / Sites and rename your default site to Signup.'));
            String path = '/sites/servlet.SiteDebugMode';
            PageReference pr = new PageReference(path);
            pr.getParameters().put('guid', Sitio.GuestUserId);
            pr.getParameters().put('sitedebugmode', 'x');
            if (Test.isRunningTest()) {
                BaseURL = 'BaseURL';
            } else {
                BaseUrl = pr.getContent().toString().substringAfter('URL=').substringBefore(path);
                system.debug('In controller, BaseURL is calculated to be ' + BaseURL);
            }
        } catch (QueryException e) {
            System.debug(e.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'Sorry, cannot find the site named Signup, which is required for WG signup pages.  Please go to Setup / Sites and rename your default site to Signup.'));
        }
        return BaseURL;
    }


    //  -------------------------------------------------------------------------
//  HELPER method: sendTemplatedEmail
//  -------------------------------------------------------------------------
    public static void sendTemplatedEmail(String[] toRecipients, String[] ccRecipients, String templateApiName, ID targetObjId, Id whatId, ID orgWideEmailId, Boolean saveAsActivity, Attachment[] attachList) {
        //  templateId   must be ID of an Email template
        //  targetObjId must be a Contact, User, Lead Id -- also used in merge fields of template recipient.xxxx
        //  whatId    must be an SObject that is used in the merge fields of the template relatedTo.xxxx
        //  fromId    if non null, use current user, otherwise, use this ID (most likely an org wide no reply id)
        //  bcc      not permitted when using templates

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<Messaging.SingleEmailMessage> emails = new LIst<Messaging.SingleEmailMessage>();
        Id templateId;
        try {
            templateId = [select id, name from EmailTemplate where developername = :templateApiName].id;
        } catch (Exception e) {
            throw new QueryException ('Unable to locate EmailTemplate using name: ' + templateApiName +
                    ' refer to Setup | Communications Templates ' + templateApiName);
        }

        email.setToAddresses(toRecipients);
        email.setCcAddresses(ccRecipients);
        email.setTargetObjectId(targetObjId);
        email.setWhatId(whatId);
        email.setorgWideEmailAddressId(orgWideEmailId);
        email.setTemplateId(templateId);
        email.setSaveAsActivity(saveAsActivity);      // save email as activity on the targetObjId (i.e. Contact). Note activity can't be saved on Users

        System.debug(LoggingLevel.INFO, '** entered sendTemplatedEmail, to:' + toRecipients + ' cc:' + ccRecipients + ' templateId:' + templateId + ' targetObjId:' + targetObjId +
                ' whatId:' + whatId + ' orgWideEmailId: ' + orgWideEmailId);
        emails.add(email);
        try {
            Messaging.sendEmail(emails, false);
            return;
        } catch (EmailException e) {
            throw new EmailException('sendTemplatedEmail error. ' + e.getMessage());
        }
    }

    public static void sendTemplatedEmails(List<CampaignMember> CMs,
            Id TemplateId, String TemplateName, Id OWEmailId, Boolean SaveActivity) {
        //  templateId   must be ID of an Email template
        //  targetObjId must be a Contact, User, Lead Id -- also used in merge fields of template recipient.xxxx
        //  whatId    must be an SObject that is used in the merge fields of the template relatedTo.xxxx
        //  fromId    if non null, use current user, otherwise, use this ID (most likely an org wide no reply id)
        //  bcc      not permitted when using templates
        Id TId = (Id) TemplateId;

        List<Messaging.SingleEmailMessage> ListEmails = new LIst<Messaging.SingleEmailMessage>();
        if (String.IsNotBlank((String) TemplateId)) {
        } else {
            try {
                Tid = [select id, name from EmailTemplate where developername = :TemplateName].id;
            } catch (Exception e) {
                throw new QueryException ('Unable to locate EmailTemplate using name: ' + TemplateName +
                        ' refer to Setup | Communications Templates ' + TemplateName);
            }
        }
        For (CampaignMember cm : CMs) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.settemplateId(TId);
            email.setTargetObjectId(cm.ContactId);
            email.setWhatId(cm.Id);
            email.setorgWideEmailAddressId(OWEmailId);
            email.setSaveAsActivity(saveActivity);
            // save email as activity on the targetObjId (i.e. Contact). Note activity can't be saved on Users

            System.debug(LoggingLevel.INFO, '** entered sendTemplatedEmail, totargetObjId:' + cm.ContactId +
                    ' templateId:' + TId + ' whatId:' + cm.Id + ' orgWideEmailId: ' + OWEmailId);
            ListEmails.add(email);
            CM.AutosendTY__c = 'sent';
        }
        List<Messaging.SendEmailResult> LSEM = Messaging.sendEmail(ListEmails, true);
        Boolean Anyerrors;
        For (Messaging.SendEmailResult SEM : LSEM) {
            system.debug('SendEmailResult is ' + SEM.isSuccess());
            if (!SEM.isSuccess()) {
                System.StatusCode statusCode = SEM.getErrors()[0].getStatusCode();
                String errorMessage = SEM.getErrors()[0].getMessage();
                system.debug('Email error message is ' + errorMessage);
                Anyerrors = true;
            }
        } if (Anyerrors == false) {
            update CMs;
        }
    }

    private static WGSettings__mdt WGSettings;

    public static WGSettings__mdt getWGSettings() {
        if (WGSettings == null) {
            string querystring = 'select ';
            List<String> types = new String[]{
                    'WGSettings__mdt'
            };
            DescribeSObjectResult[] results = Schema.describeSObjects(types);
            System.debug('Got describe information for ' + results.size() + ' sObjects.');
            for (Schema.DescribeSobjectResult res : results) {
                Map<String, Schema.SObjectField> fieldsMap = res.fields.getMap();
                system.debug('Fields are ' + fieldsMap.keySet());
                For (string s : fieldsMap.keyset()) {
                    querystring += s + ', ';
                }
                querystring = querystring.LEFT(querystring.length() - 2) + ' from WGSettings__mdt LIMIT 1';

                WGSettings = Database.query(querystring);
            }
        }
        RETURN WGSettings;
    }

    @testVisible private static Boolean BUseACRelations;

    public static Boolean getUseACRelations() {
        if (BUseACRelations == null) {
            BUseACRelations = [
                    SELECT Use_AcctCtctRelations__c
                    from WGSettings__mdt
                    WHERE DeveloperName = 'WGDefault'
                    LIMIT 1
            ].Use_AcctCtctRelations__c;
        }
        system.debug('WGHelpers returns Use_AcctCtctRelations__c of ' + BUseACRelations);
        return BUseACRelations;
    }

    @testVisible private static Boolean BManageContacts;

    public static Boolean getManageContactsSetting() {
        if (BManageContacts == null) {
            BManageContacts = [
                    SELECT ManageContacts__c
                    from WGSettings__mdt
                    WHERE DeveloperName = 'WGDefault'
                    LIMIT 1
            ].ManageContacts__c;
        }
        return BManageContacts;
    }

    @testVisible private static Boolean BManageACRelations;

    public static Boolean getManageACRelations() {
        if (BManageACRelations == null) {
            BManageACRelations = [
                    SELECT ManageACRelations__c
                    from WGSettings__mdt
                    WHERE DeveloperName = 'WGDefault'
                    LIMIT 1
            ].ManageACRelations__c;
        }
        return BManageACRelations;
    }

    @testVisible private static Boolean BManageContactEmails;
    public static Boolean getManageContactEmailsSetting() {
        if (BManageContactEmails == null) {
            BManageContactEmails = [
                    SELECT ManageContactEmails__c
                    from WGSettings__mdt
                    WHERE DeveloperName = 'WGDefault'
                    LIMIT 1
            ].ManageContactEmails__c;
        }
        return BManageContactEmails;
    }

    @testVisible private static Boolean BManageOCRs;
    public static Boolean getManageOCRs() {
        if (BManageOCRs == null) {
            BManageOCRs = [
                    SELECT ManageOCRs__c
                    from WGSettings__mdt
                    WHERE DeveloperName = 'WGDefault'
                    LIMIT 1
            ].ManageOCRs__c;
        }
        return BManageOCRS;
    }

    @testVisible private static Boolean BDontUseLeads;
    public static Boolean getDontUseLeads() {
        if (BDontUseLeads == null) {
            BDontUseLeads = WGSettings__mdt.getAll().get('WGDefault').DontUseLeads__c;
        }
        return BDontUseLeads;
    }

    // Used to toggle identifyOrCreatePerson to update addresses or not
    public static Boolean NoUpdates;


    @testVisible private static Decimal BMinimumAcceptableMatchRank;

    public static Decimal getMinimumAcceptableMatchRank() {
        if (BMinimumAcceptableMatchRank == null) {
            BMinimumAcceptableMatchRank = [
                    SELECT MinimumAcceptableMatchRank__c
                    from WGSettings__mdt
                    WHERE DeveloperName = 'WGDefault'
                    LIMIT 1
            ].MinimumAcceptableMatchRank__c;
        }
        system.debug('WGHelpers returns MinimumAcceptableMatchRank__c of ' + BMinimumAcceptableMatchRank);
        return BMinimumAcceptableMatchRank;
    }


    @testVisible private static String SAddTransactionFeeTo;
    public static String getAddTransactionFeeTo() {
        if (SAddTransactionFeeTo == null) {
            SAddTransactionFeeTo = WGSettings__mdt.getAll().get('WGDefault').AddTransactionFeeTo__c;
        }
        return SAddTransactionFeeTo;
    }
}


/* THIS MAY NOT BE USEFUL, EXCEPT THAT IT DOES ALLOW US TO BE DYNAMIC WITH THE soBJECTNAME
public static Map<String,Schema.SObjectField> FieldSetWDescription(string SObjectName,string FieldSetName){
SObject obj = (SObject) Type.forName(SObjectName).newInstance();
DescribeSObjectResult objdescribe = obj.getSObjectType().getDescribe();
Schema.FieldSet fieldSetObj = objdescribe.FieldSets.getMap().get(FieldSetName);
system.debug(fieldSetObj);
List<string> LS = new List<String>();
for (Schema.FieldSetMember f : fieldsetObj.getFields()){
LS.add(f.Label);
}
system.debug('List of field labels is ' + LS);
// Find matching fieldnames
Schema.DescribeSObjectResult dsr = GUUTask__c.sObjectType.getDescribe();
Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.GUUTask__c.fields.getMap();
// Map<String,String> fieldSetHelpMap = new Map<string,string>();
// For (string s : fieldMap.keyset())
return fieldMap;
} */