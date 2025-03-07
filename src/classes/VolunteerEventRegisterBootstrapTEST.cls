/**
 * Created by Baird on 2/8/2019.
 */

@isTest
private class VolunteerEventRegisterBootstrapTEST {

    @istest
    public static void NewLeadSignsUp() {
        Create_Test_Variables ctv = new Create_Test_Variables();
        ctv.TestCampaign.Capacity__c = 3;
        ctv.TestCampaign.Event_End_Time__c = Datetime.NewInstance(2018, 12, 25, 8, 0, 0);
        ctv.TestCampaign.Waiver_Required__c = true;
        Text_Document__c TD = ctv.fetchWaiver();
        ctv.TestCampaign.Waiver__c = TD.Id;
        update ctv.TestCampaign;
        Id TestLeadId;

        Master_Campaign__c mc = new Master_Campaign__c(Name = 'TestMasterCamp');
        // This time we are not specifying the master_campaign_id;
        // The setMasterCAmpaign() method should run even without the master_campaign_Id;
        insert mc;

        //System.currentPageReference().getParameters().put('mid', mc.Id);
        System.currentPageReference().getParameters().put('cid', ctv.TestCampaign.Id);
        TestLeadId = ctv.TestLead.Id;
        System.currentPageReference().getParameters().put('coid', ctv.TestContact.Id);
        System.currentPageReference().getParameters().put('lid', ctv.TestLead.Id);

        VolunteerEventRegisterBootstrap ve = new VolunteerEventRegisterBootstrap();

        ve.setMasterCampaign();

        ve.setSignUp();

        System.currentPageReference().getParameters().remove('coid');

        ve.setSignUp();

        ve.setSignee();

        ve.coc.email = ctv.TestContact.Email;
        ve.coc.lastName = ctv.TestContact.LastName;

        ve.setSignee();

        ve.step = '3';

        ve.setSignUp();

        ve.coc.street = '122 street';
        ve.coc.city = 'Miami';
        ve.coc.state = 'FL';
        ve.coc.volunteerInterests.add('Education and Outreach');
        ve.coc.howHeard = 'Google';

        ve.updateSignee();
        ve.DeclineWaiver = true;
        ve.toggleAccept();
        ve.coc.newsletter = true;
        system.assertEquals(true, ve.DeclineWaiver);
        system.assertEquals(false, ve.AcceptWaiver);

        ve.signUp();
        system.assert(ve.errors.CONTAINS('You must accept the waiver'), 'SignUp method did not catch DeclineWaiver=true and let person sign up anyway.');
        ve.AcceptWaiver = true;
        ve.toggleAccept();
        system.assertEquals(false, ve.DeclineWaiver);
        system.assertEquals(true, ve.AcceptWaiver);

        ve.signUp();
        List<CampaignMember> testresult = [select id, Nr_in_Group__c from campaignmember where campaignid = :ve.c.id];
        system.assertEquals(1, testresult.size());
        system.assertEquals(1, testresult[0].Nr_in_Group__c, 'CM inserted without specifying Nr_in_Group__c and should have been set to 1.');
        WGSettings__mdt Setting = WGHelpers.getWGSettings();
        Lead ResultLead = [SELECT Mailing_Lists__c from Lead where id =: TestLeadId];
        System.assertEquals(Setting.Online_signup_newsletter__c,ResultLead.Mailing_Lists__c,'Should have set mailing_lists to e-newsletter');

        System.currentPageReference().getParameters().put('coid', ctv.TestContact.Id);
        ve.setSignUp();

        ve.step = '2';

        ve.signUp();

        ve.setSignee();

        ve.coc.email = 'testemail2@test.com';
        ve.coc.lastName = 'SecondLead';

        ve.setSignup();
        ve.setSignee();
        ve.signUp();
        system.assertEquals(2, [select id from campaignmember where campaignid = :ve.c.id].size());

// Add a third campaign member
        System.currentPageReference().getParameters().remove('coid');
        System.currentPageReference().getParameters().put('cid', ctv.TestCampaign.Id);
// Enter data for initial page
        VolunteerEventRegisterBootstrap ve2 = new VolunteerEventRegisterBootstrap();
        ve2.setSignup();
        system.assertEquals(null, System.currentPageReference().getParameters().get('coid'));
        ve2.coc.firstname = 'Test';
        ve2.coc.email = 'testemail3@test.com';
        ve2.coc.lastName = 'ThirdLead';
        ve2.coc.zip = '33333';
// Submit button calls setSignee();
        ve2.setSignee();
// Setsignee() creates a new lead;
        system.assert(string.IsNotEmpty(ve2.ld.Id));
        ve2.step = '3';
        system.currentPageReference().getParameters().put('lid', ve2.ld.Id);
// Now the page is refreshed, setSignUp() is called again;
        ve2.setSignUp();
// Because lid <> null and street, city etc are blank step is set to '2';
// system.assertEquals('2',ve2.step,'SetSignUp should set step to 2 to get missing address info.');
        ve2.coc.street = 'Third campaignmember street';
        ve2.coc.city = 'Third campaignmember city';
        ve2.coc.state = 'Third campaignmember state';
        Contact newCtct = new Contact(lastname = 'TestCtct3', accountId = ctv.testaccount.Id);
        Insert newCtct;
        CampaignMember newCM = new CampaignMember(contactId = newCtct.Id, CampaignId = ve2.c.Id, Role__c = 'Volunteer', Nr_in_Group__c = 1);
        Insert newCM;
        ve.setSignUp();

// system.assertEquals('This event is full. Please try a different one.', ve.Errors, 'Once the capacity is reached, no one else can sign up.');
    }

    @istest
    public static void signUpExistingContact() {
        Create_Test_Variables ctv = new Create_Test_Variables();
        Contact TestContact = ctv.fetchTestContact();
        Campaign camp = ctv.fetchTestCampaign();
        Camp.CompletionURL__c='https://google.com';
        system.debug('TestContact is ' + TestContact);

        Master_Campaign__c mc = new Master_Campaign__c(Name = 'Test');
        insert mc;
        camp.Master_Campaign__c = mc.Id;

//        Text_Document__c TD = ctv.fetchWaiver();
//        ctv.TestCampaign.Waiver__c = TD.Id;
        update camp;

        System.currentPageReference().getParameters().put('mid', mc.Id);
        System.currentPageReference().getParameters().put('cid', camp.Id);
        System.currentPageReference().getParameters().put('coid', ctv.TestContact.Id);
        // System.currentPageReference().getParameters().put('lid', ctv.TestLead.Id);

        VolunteerEventRegisterBootstrap ve = new VolunteerEventRegisterBootstrap();

        ve.setMasterCampaign();

        ve.setSignUp();
        system.debug('After setSignup, Contact Custom is ' + ve.coc);

        // System.currentPageReference().getParameters().remove('coid');

        // ve.setSignUp();

        ve.setSignee();

        ve.coc.email = ctv.TestContact.Email;
        ve.coc.lastName = ctv.TestContact.LastName;

        ve.setSignee();
        ve.coc.setVolunteerInterests();

        ve.coc.volunteerInterests.add('Education and Outreach');
        ve.coc.howHeard = 'Google';
        ve.AcceptWaiver=true;

        system.debug('Contact Custom is now ' + ve.coc);

        List<CampaignMember> CMs = [select id, contact.email, contactId, leadId, lead.email from CampaignMember where campaignId = :ve.c.Id];
        system.debug('CampaignMembers are ' + CMs);

        PageReference CompletionURLRef = new PageReference('https://google.com');
        // Run the signup() method.
        // Does the ExitToCompletionURL method give the right URl?
        PageReference TestPR = ve.Signup();
        system.debug('Resulting PageReference is ' + TestPR);
        //system.assertEquals(CompletionURLRef.getURL(),ve.signUp().getURL());
        CMs = [select id, contact.email, contactId, leadId, lead.email from CampaignMember where campaignId = :ve.c.Id];
        system.debug('CampaignMembers are ' + CMs);
        system.assertEquals(TestContact.Id, CMs[0].ContactId, 'The contact should now be a campaignMember.');
        system.assertEquals(STRING.VALUEOF(CompletionURLRef.getURL()),ve.ExitToCompletionURL().getURL(), 'ExitToCompletionURL method not working');
    }

    @istest
    public static void CorporateVolEventTest() {
        Create_Test_Variables ctv = new Create_Test_Variables();

        Master_Campaign__c mc = new Master_Campaign__c(Name = 'TestMasterCamp');
        insert mc;

        System.currentPageReference().getParameters().put('mid', mc.Id);
        System.currentPageReference().getParameters().put('cid', ctv.TestCampaign.Id);
        System.currentPageReference().getParameters().put('coid', ctv.TestContact.Id);
        System.currentPageReference().getParameters().put('lid', ctv.TestLead.Id);

        VolunteerEventRegisterBootstrap ve = new VolunteerEventRegisterBootstrap();

        ctv.testcampaign.Master_Campaign__c = mc.id;
        ctv.testcampaign.Type = 'Corporate volunteer event';
        update ctv.testcampaign;
        Campaign c = ctv.testcampaign;

        ve.setMasterCampaign();
        system.assertEquals(1, [select id from campaign].size());
        system.assertEquals('Testcampaign', ve.cs[0].name, 'Mastercampaign Id failed to link to correct campaign.');

        ve.setSignUp();

//Test to make sure that cid campaign no longer appears in general listing

        System.currentPageReference().getParameters().remove('coid');

        ve.setSignUp();
        ve.setSignee();

        ve.coc.email = ctv.TestContact.Email;
        ve.coc.lastName = ctv.TestContact.LastName;

        ve.setSignee();

        ve.step = '3';

        ve.setSignUp();

        ve.coc.street = '122 street';
        ve.coc.city = 'Miami';
        ve.coc.state = 'FL';
        ve.coc.volunteerInterests.add('Education and Outreach');
        ve.coc.howHeard = 'Google';

        ve.updateSignee();

        ve.co = ctv.fetchTestContact();
        ve.signUp();

        System.currentPageReference().getParameters().put('coid', ctv.TestContact.Id);

        ve.setSignUp();

        ve.step = '2';
        ve.AcceptWaiver = true;
        ve.signUp();

//Delete campaignMember, Opportumity
        List<Campaign> TestCampResults = [select id, Slots_Reserved__c, (select id, Nr_in_Group__c from CampaignMembers) from Campaign where id = :c.Id];
        system.AssertEquals(1, TestCampResults.size(), 'Should have only created one campaign member in Testcampaign');

        List<CampaignMember> CMDeleteList = [select id from CampaignMember where campaignId = :c.Id];
        delete CMDeleteList;
        Delete ve.o;
        ve.o = new Opportunity();

        System.currentPageReference().getParameters().put('cid', c.Id);

        ve.setSignUp();
        ve.cm.Nr_in_Group__c = 25;
        ve.cm.Role__c = 'Group leader';

        ve.signUp();

        system.assertEquals('Group leader', ve.cm.Role__c, 'If one person signs up, they become a leader.');
        TestCampResults = [select id, Slots_Reserved__c from Campaign where id = :c.Id];
        system.assertEquals(1, TestCampResults[0].Slots_Reserved__c, 'Group leader signed up for 25 but for Corporate Event gets counted as 1');

// Now the campaign should no longer appear in the master campaign list
// Sign up a new volunteer;
        VolunteerEventRegisterBootstrap VE2 = new VolunteerEventRegisterBootstrap();
        ve2.setMasterCampaign();
        system.assertEquals(0, ve2.cs.size(), 'Now that one Group leader has signed up, this corporate volunteer campaign should no longer be in the select page.');

        ve2.setSignUp(); ve.setSignee();

        ve2.coc.email = 'garbage@garbage.com';
        ve2.coc.lastName = 'Second Signup';

        ve2.setSignee();

        ve2.step = '3';

        ve2.cm.Nr_in_Group__c = null;
        ve2.AcceptWaiver = true;
        ve2.signUp();

        system.assertEquals('Volunteer', ve2.cm.Role__c, 'A second person to sign up becomes a follower.');
        List<Opportunity> checkOpps = [select id, campaignId from Opportunity where campaignId = :c.Id];
        system.assertEquals(1, checkOpps.size(), 'Should only be one donation from the Group leader.  Otherwise, the create opportunity routine is probably firing twice.');
        system.assertEquals(c.Id, checkOpps[0].campaignId, 'Contribution not attributed to campaign');

// Test that slots_reserved are being calculated correctly
        TestCampResults = [select id, Slots_Reserved__c from Campaign where id = :c.Id];
        system.assertEquals(2, TestCampResults[0].Slots_Reserved__c, 'Volunter signed up and did not change the count in number_in_group');
    }

    @istest
    public static void DuplicateCampaignMember() {
        Create_Test_Variables ctv = new Create_Test_Variables();
        Contact TestContact = ctv.fetchTestContact();
        Campaign camp = ctv.fetchTestCampaign();
        Camp.CompletionURL__c='google.com';
        system.debug('TestContact is ' + TestContact);

        Master_Campaign__c mc = new Master_Campaign__c(Name = 'Test');
        insert mc;
        camp.Master_Campaign__c = mc.Id;

//        Text_Document__c TD = ctv.fetchWaiver();
//        ctv.TestCampaign.Waiver__c = TD.Id;
        update camp;

        System.currentPageReference().getParameters().put('mid', mc.Id);
        System.currentPageReference().getParameters().put('cid', camp.Id);
        System.currentPageReference().getParameters().put('coid', ctv.TestContact.Id);
        // System.currentPageReference().getParameters().put('lid', ctv.TestLead.Id);

        VolunteerEventRegisterBootstrap ve = new VolunteerEventRegisterBootstrap();

        ve.setMasterCampaign();

        ve.setSignUp();
        system.debug('After setSignup, Contact Custom is ' + ve.coc);

        ve.setSignee();

        ve.coc.email = ctv.TestContact.Email;
        ve.coc.lastName = ctv.TestContact.LastName;

        ve.setSignee();
        ve.coc.setVolunteerInterests();

        ve.coc.volunteerInterests.add('Education and Outreach');
        ve.coc.howHeard = 'Google';
        ve.AcceptWaiver=true;

        system.debug('Contact Custom is now ' + ve.coc);

        List<CampaignMember> CMs = [select id, contact.email, contactId, leadId, lead.email from CampaignMember where campaignId = :ve.c.Id];
        system.debug('CampaignMembers are ' + CMs);

        PageReference CompletionURLRef = new PageReference('http://google.com');
        // Run the signup() method.
        // Does the ExitToCompletionURL method give the right URl?
        PageReference TestPR = ve.Signup();
        system.debug('Resulting PageReference is ' + TestPR);
        //system.assertEquals(CompletionURLRef.getURL(),ve.signUp().getURL());
        CMs = [select id, contact.email, contactId, leadId, lead.email from CampaignMember where campaignId = :ve.c.Id];
        system.debug('CampaignMembers are ' + CMs);
        system.assertEquals(TestContact.Id, CMs[0].ContactId, 'The contact should now be a campaignMember.');

        // SIGN THEM UP AGAIN

        System.currentPageReference().getParameters().put('cid', camp.Id);
        ve = new VolunteerEventRegisterBootstrap();
        ve.setMasterCampaign();
        ve.setSignup();
        system.debug('TestContact is ' + TestContact);
        ve.coc.email = TestContact.Email;
        ve.coc.lastName = TestContact.LastName;
        ve.setSignee();
        system.assertEquals(true,ve.DuplicateCampMember,'After adding same contact to campaign twice, should have found the Duplicate');
    }

    @istest
    public static void MasterCampWCamps() {
        Master_Campaign__c mc = new Master_Campaign__c(Name = 'TestMasterCamp');
        // This time we are not specifying the master_campaign_id;
        // The setMasterCAmpaign() method should run even without the master_campaign_Id;
        insert mc;
        System.currentPageReference().getParameters().put('mid', mc.Id);
        Create_Test_Variables ctv = new Create_Test_Variables();
        ctv.TestCampaign.Capacity__c = 3;
        ctv.TestCampaign.Event_End_Time__c = Datetime.Now().addDays(3);
        ctv.TestCampaign.Waiver_Required__c = true;
        Text_Document__c TD = ctv.fetchWaiver();
        ctv.TestCampaign.Waiver__c = TD.Id;
        ctv.TestCampaign.Master_Campaign__c = mc.Id;
        // Id VolTaskRTID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Volunteer Task').getRecordTypeId();
        // ctv.TestCampaign.RecordTypeId = VolTaskRTID;
        update ctv.TestCampaign;
        Id TestLeadId;

        VolunteerEventRegisterBootstrap ve = new VolunteerEventRegisterBootstrap();

        ve.setMasterCampaign();
        system.assertEquals('TestMasterCamp',ve.title,'Should have set page title to Master CAmpaign title');
    }

    @istest
    public static void MasterCampWNoCamps() {
        Create_Test_Variables ctv = new Create_Test_Variables();
        ctv.TestCampaign.Capacity__c = 3;
        ctv.TestCampaign.Event_End_Time__c = Datetime.NewInstance(2018, 12, 25, 8, 0, 0);
        ctv.TestCampaign.Waiver_Required__c = true;
        Text_Document__c TD = ctv.fetchWaiver();
        ctv.TestCampaign.Waiver__c = TD.Id;
        update ctv.TestCampaign;
        Id TestLeadId;

        Master_Campaign__c mc = new Master_Campaign__c(Name = 'TestMasterCamp');
        // This time we are not specifying the master_campaign_id;
        // The setMasterCAmpaign() method should run even without the master_campaign_Id;
        insert mc;
        System.currentPageReference().getParameters().put('mid', mc.Id);

        VolunteerEventRegisterBootstrap ve = new VolunteerEventRegisterBootstrap();

        ve.setMasterCampaign();
        system.assertEquals(ve.errors,'Could not find any events listed in that master campaign.','Should have objected that master campaign contained no campaigns.');
    }

    // Benita and Bill find that if registrants enter new names with existing emails,
    // the old names of the contacts with those emails are changed to the new names.
    // The problem lies in the setsignee, which updates the contact name.
    @istest
    public static void NamesDontChange() {
        Create_Test_Variables ctv = new Create_Test_Variables();
        Contact TestContact = ctv.fetchTestContact();
        Campaign camp = ctv.fetchTestCampaign();
        Camp.CompletionURL__c = 'google.com';
        system.debug('TestContact is ' + TestContact);

        Master_Campaign__c mc = new Master_Campaign__c(Name = 'Test');
        insert mc;
        camp.Master_Campaign__c = mc.Id;

//        Text_Document__c TD = ctv.fetchWaiver();
//        ctv.TestCampaign.Waiver__c = TD.Id;
        update camp;

        System.currentPageReference().getParameters().put('mid', mc.Id);
        System.currentPageReference().getParameters().put('cid', camp.Id);
        System.currentPageReference().getParameters().put('coid', ctv.TestContact.Id);
        // System.currentPageReference().getParameters().put('lid', ctv.TestLead.Id);

        VolunteerEventRegisterBootstrap ve = new VolunteerEventRegisterBootstrap();

        ve.setMasterCampaign();

        ve.setSignUp();
        system.debug('After setSignup, Contact Custom is ' + ve.coc);
        ve.coc.email = ctv.TestContact.Email;
        ve.coc.lastName = 'ChangedLastName';
        ve.coc.firstname = 'ChangedFirstName';
        ve.coc.zip = ctv.TestContact.MailingPostalCode;
        ve.setSignee();

        Contact result = [SELECT Id, FirstName, LastName, MailingPostalCode
        from Contact WHERE id =: TestContact.Id];
        system.assertEquals(ctv.TestContact.FirstName,result.Firstname);
        system.assertEquals(ctv.TestContact.LastName,result.Lastname);
    }

    @istest
    public static void NamesDontChangeLead() {
        Create_Test_Variables ctv = new Create_Test_Variables();
        Lead TestLead = ctv.fetchTestLead();
        Campaign camp = ctv.fetchTestCampaign();
        Camp.CompletionURL__c = 'google.com';
        system.debug('TestLead is ' + TestLead);

        Master_Campaign__c mc = new Master_Campaign__c(Name = 'Test');
        insert mc;

        camp.Master_Campaign__c = mc.Id;
        update camp;

        System.currentPageReference().getParameters().put('mid', mc.Id);
        System.currentPageReference().getParameters().put('cid', camp.Id);
        System.currentPageReference().getParameters().put('lid', ctv.TestLead.Id);
        // System.currentPageReference().getParameters().put('lid', ctv.TestLead.Id);

        VolunteerEventRegisterBootstrap ve = new VolunteerEventRegisterBootstrap();

        ve.setMasterCampaign();

        ve.setSignUp();
        system.debug('After setSignup, Contact Custom is ' + ve.coc);
        ve.coc.email = ctv.TestLead.Email;
        ve.coc.lastName = 'ChangedLastName';
        ve.coc.firstname = 'ChangedFirstName';
        ve.coc.zip = ctv.TestLead.PostalCode;
        ve.coc.newsletter = false;
        ve.setSignee();

        Lead result = [SELECT Id, FirstName, LastName, PostalCode, HasOptedOutOfEmail
        from Lead WHERE id =: TestLead.Id];
        system.assertEquals(ctv.TestLead.FirstName,result.Firstname);
        system.assertEquals(ctv.TestLead.LastName,result.Lastname);
        system.assertEquals(false,result.HasOptedOutOfEmail,'Should no longer opt out of email just because registrant does not want the newsletter.');
    }

    // Steven at BOP finds that new leads are saved without email.
    // Also that when a registrant opts out of the email newsletter,
    // the contact opt-out is set.
    // on 6/3/2021 I correct and write this test.
    @istest
    public static void NewLead() {
        Create_Test_Variables ctv = new Create_Test_Variables();
        Lead TestLead = ctv.fetchTestLead();
        Campaign camp = ctv.fetchTestCampaign();
        Camp.CompletionURL__c = 'google.com';
        system.debug('TestLead is ' + TestLead);

        Master_Campaign__c mc = new Master_Campaign__c(Name = 'Test');
        insert mc;

        camp.Master_Campaign__c = mc.Id;
        update camp;

        System.currentPageReference().getParameters().put('mid', mc.Id);
        System.currentPageReference().getParameters().put('cid', camp.Id);
        // System.currentPageReference().getParameters().put('lid', ctv.TestLead.Id);

        VolunteerEventRegisterBootstrap ve = new VolunteerEventRegisterBootstrap();

        ve.setMasterCampaign();

        ve.setSignUp();
        system.debug('After setSignup, Contact Custom is ' + ve.coc);
        ve.coc.email = 'notyouraverage@email.com';
        ve.coc.lastName = 'ChangedLastName';
        ve.coc.firstname = 'ChangedFirstName';
        ve.coc.zip = ctv.TestLead.PostalCode;
        // SetSignee should find no match; should create a new Lead.
        ve.setSignee();

        Lead result = [SELECT Id, Email, Personal_Email__c, Work_Email__c, Other_Email__c, FirstName, LastName, PostalCode
        from Lead WHERE LastName =: 'ChangedLastName' LIMIT 1];
        system.debug('Resulting lead is ' + result);
        system.assertEquals('ChangedFirstName',result.Firstname);
        system.assertEquals('ChangedLastName',result.Lastname);
        system.assertEquals('notyouraverage@email.com',result.Email);
    }
}