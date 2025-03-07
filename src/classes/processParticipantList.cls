// Jan 31 Jose revises so users can add campaign members without refreshing whole page and erasing data they've already input.
// Nov 10 2016 Baird makes sure this inserts addressee and dear.
// Apr 2019 Baird rewrites to avoid using overly engineered code.
// Oct 6 2021 Baird bulkifies the lead conversion section., after users reported
// exceeding the SOQL limit with just 28 records.

    public class processParticipantList {
    public List<Attendee> UnprocessedAttendees { get; set; }
    public List<AttendeeWrapper> UnprocessedAttWrapped { get; set; }
    public List<Attendee> UpdateAttendees { get; set; }
    List<CampaignMember> ListCMs { get; set; }
    public List<CampaignMember> UpdateCMs;
    public Campaign Camp { get; set; }
    public Boolean review { get; set; } // Value to render review pageBlock;
    public Boolean newContactForm { get; set; }
    public Id VolContribId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Volunteer Task').getRecordTypeId();
    public Decimal TotalHours { get; set; }
    public LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
    public Id cid { get; set; }
    // Is FamilyRTID used anywhere?
    public Id FamilyRTID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Family').getRecordTypeId();
    public integer AttendeeToDeleteIndex { get; set; }
    public CampaignMember CMToDelete { get; set; }

    static public String DefaultRating = '3 - Good';
    static public List<Schema.PicklistEntry> LeadershipLevels { get; set; }
    public String DefaultLeadership { get; set; }

    public Attendee attendee { get; set; }
    public Contact NewContact { get; set; }
    public Id PersonId { get; set; }
    public Attendee all { get; set; }
    public Decimal allHours { get; set; }
    public string allStatus { get; set; }
    public string allRoles { get; set; }
    public string Loc { get; set; } // string holder so I can insert multiple locations into Location_of_Task field

    public List<FieldSetCustom> ofs { get; set; }
    public Contact co2 { get; set; }
    public List<Schema.FieldSetMember> pPLFieldSetMembers { get; set; }
    public Boolean ManageContactsSetting;

    public processParticipantList(ApexPages.StandardController stdController) {
        LeadershipLevels = Opportunity.Leadership_Level__c.getDescribe().getPicklistValues();
        DefaultLeadership = getDefaultValue(Opportunity.Leadership_Level__c.getDescribe(), 0);
        pPLFieldSetMembers = SObjectType.Opportunity.fieldSets.ParticipantListFieldset.getFields();
        CMToDelete = new CampaignMember();
        review = false;
        cid = System.currentPageReference().getParameters().get('cid');
        system.debug('At top of constructor, cid is ' + cid);
        if (cid == null) {
            DisplayNoCAmpaignWarning();
        } else {
            try {
                Camp = [select Id, campaign.Name, Event_Date_Time__c from Campaign where Id = :cid];
                attendee = new Attendee(Camp);
                all = new Attendee(Camp);
                newContactForm = false;
                // NewContact = new Contact();
                PersonId = null;
                ListCMs = [
                        select Id, Name, ContactId, Contact.FirstName, Contact.LastName, Contact.Email, Contact.AccountId, LeadId, Lead.FirstName,
                                Lead.LastName, Lead.IsConverted, Hours__c, Status, Role__c, Processed__c
                        from CampaignMember
                        where Campaign.Id = :Camp.Id and Processed__c <> true
                        order by Contact.FirstName, Lead.FirstName
                        limit 1000
                ];
                UnprocessedAttendees = new List<Attendee>();
                UnprocessedAttWrapped = new List<AttendeeWrapper>();
                FOR (CampaignMember cm : ListCMs) {
                    UnprocessedAttendees.add(new Attendee(cm));
                }
                UpdateAttendees = new List<Attendee>();
            } catch (QueryException e) {
                DisplayBadCampIdWarning();
            }
            Integer counter = 0;
            if (UnprocessedAttendees != null) {
                for (Attendee at : UnprocessedAttendees) {
                    // add the wrapper to the collection
                    UnprocessedAttWrapped.add(new AttendeeWrapper(at, counter));
                    counter = counter + 1;
                }
            }
        }
    }

//Get List of Status Values
    public List<SelectOption> getStati() {
        List<SelectOption> stati = new List<SelectOption>();
        // Baird revised Jose's query to pull the CampaignMemberStati from the campaign itself
        for (CampaignMemberStatus cms : [SELECT Id, Label FROM CampaignMemberStatus WHERE CampaignId = :cid])
            stati.add(new SelectOption(cms.Label, cms.Label));
        return stati;
    }

    public List<SelectOption> getRoles() {
        List<SelectOption> options = new List<SelectOption>();
        // Baird revised Jose's query to pull the CampaignMemberStati from the campaign itself
        Schema.DescribeFieldResult fieldResult =
                CampaignMember.Role__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        return options;
    }

    static public String getDefaultValue(Schema.DescribeFieldResult field, Integer index) {
        List<Schema.PicklistEntry> sspl = field.getPicklistValues();
        if (index >= sspl.size())
            index = 0;
        return sspl[index].getLabel();
    }

    public void setAllStatus() {
        string passedParam1 = Apexpages.currentPage().getParameters().get('allStatus');
        system.debug('Passed in myParam ' + passedParam1);
        for (Attendee a : UnprocessedAttendees) {
            if (String.isNotBlank(passedParam1))
                a.CM.Status = passedParam1;

            if (a.Hours == 0)
                a.Hours = null;
        }

        if (allHours == 0)
            allHours = null;
    }

    public void setAllHours() {
        system.debug('Passed in allHours ' + allHours);
        for (Attendee a : UnprocessedAttendees) {
            a.Hours = allHours;
        }
    }

    public void setAllRoles() {
        system.debug('Passed in allRoles ' + allRoles);
        for (Attendee a : UnprocessedAttendees) {
            a.CM.Role__c = allRoles;
        }
    }

    public void formatsRSVPedList() {
        for (Attendee a : UnprocessedAttendees) {
            if (a.Hours == 0)
                a.Hours = null;
        }
    }


    public void processSelected() {
        if (Camp.Event_Date_Time__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter the date and time of the event below.'));
        } else {
            newContactForm = false;
            UpdateCMs = new List<CampaignMember>();
            TotalHours = 0;

            for (Attendee a : UnprocessedAttendees) {
                System.debug('Going through UnprocessedCMs to add to UpdateAttendees');
                // MAKE SURE HOURS ARE NULL RATHER THAN 0
                if (a.Hours == 0)
                    a.Hours = null;

                // If user has changed hours, comments, rating, or status

                if ((a.Hours > 0) || string.IsNotBlank(a.Comments) || a.Contribution.Supervisor_Satisfaction__c != processParticipantList.DefaultRating || a.OriginalStatus != a.CM.Status) {
                    system.debug('a.Hours != blank? ' + string.ValueOf(a.Hours != null) + 'a.Comments != blank? ' + string.ValueOf(a.Comments != '') + 'a.Contribution.Supervisor_Satisfaction__c != DefaultRating? ' + string.ValueOf(a.Contribution.Supervisor_Satisfaction__c != DefaultRating) + 'a.OriginalStatus != a.CM.Status?' + string.ValueOf(a.OriginalStatus != a.CM.Status));
                    SYSTEM.debug('a.Comments are ' + a.Comments + 'and a.Supervisor_Satisfaction is ' + a.Contribution.Supervisor_Satisfaction__c + ' and Default RAting is ' + DefaultRating);
                    UpdateAttendees.add(a);
                    if (a.Hours != null)
                        TotalHours += a.Hours;

                    if (UpdateAttendees.size() == 0)
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No members were processed'));

                    if (!ApexPages.hasMessages())
                        system.debug('Error messages are ' + ApexPages.getMessages());
                    review = true;
                }
            }
        }
    }


//Back to WaterGrass
    public PageReference exitToWaterGrass() {
        PageReference nextPage = new PageReference('/' + Camp.Id);
        nextPage.setRedirect(true);
        return nextPage;
    }


//REturn to Edit List
    public PageReference returnToEditList() {
        review = false;
        UpdateAttendees.clear();
        return null;
    }

    public void addToList() {
        system.debug('PersonId is ' + personId);
        if (string.IsNotBlank(personId))
            addToList(PersonId);
    }

    public void addToList(Id PersonId) {
        system.debug('Beginning AddToList(), UnprocessedAttendees number ' + UnprocessedAttendees.size());
        // CREATE LIST OF EXISTING CAMPAIGN MEMBERS
        Map<Id, CampaignMember> MapCMs = new Map<Id, CampaignMember>();
        For (CampaignMember cm : ListCMs) {
            If (cm.contactId != null) {
                MapCMs.put(cm.contactId, cm);
            } else {
                MapCMs.put(cm.leadId, cm);
            }
        }
        // COMPARE NEW CM TO LIST TO MAKE SURE IT'S REALLY NEW
        if (MapCMs.containsKey(PersonId)) {
            if (MapCMs.get(PersonId).Processed__c) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'That campaign member has already been processed. If you want to process them again, or un-process them, go to the campaign member list, edit them, and remove the check in the "Processed" check box.'));
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Campaign Member is already in this list.'));
            }
        } else // CREATE NEW CAMPAIGNMEMBER FROM EXISTING CONTACT OR LEAD
        {
            CampaignMember newcm = new CampaignMember(
                    LeadId = string.valueOf(PersonId).startswith('003') ? null : PersonId,
                    ContactId = string.valueOf(PersonId).startswith('003') ? PersonId : null,
                    CampaignId = Camp.Id,
                    Status = 'Attended'
            );
            insert newcm;
            CampaignMember ShowCM = [
                    select Id, Name, ContactId, Contact.FirstName, Contact.LastName, Contact.Email, Contact.AccountId, LeadId, Lead.FirstName,
                            Lead.LastName, Lead.IsConverted, Hours__c, Status, Role__c, Processed__c
                    from CampaignMember
                    where id = :newcm.Id
            ];
            system.debug('After inserting new campaignMember, does it have a name? ' + showcm.Name);
            // newcm.lastname = newcm.contact.lastname == null ? newcm.lead.lastname : newcm.contact.lastname;
            ListCMs.add(showcm);

            UnprocessedAttendees.add(new Attendee(showcm));
            system.debug('After AddToList(), UnprocessedAttendees number ' + UnprocessedAttendees.size());
            system.debug('After AddtoList(), DefaultLeadership is ' + DefaultLeadership);
            integer j = UnprocessedAttWrapped.size();
            UnprocessedAttWrapped = new List<AttendeeWrapper>();
            FOR (Attendee at : UnprocessedAttendees) {
                UnprocessedAttWrapped .add(new AttendeeWrapper(at, j));
            }
        }
        // requery list; refresh screen;
        formatsRSVPedList();
        system.debug('Finished addToList, should now rerender PeopleWhoRSVPed section.');
    }

    public void addNewContact() {
        newContact = new Contact();
        newContactForm = true;
    }

    public void cancelContact() {
        newContactForm = false;
    }

    public void savePerson() {
        ManageContactsSetting = WGHelpers.getManageContactsSetting();
        system.debug('In PPL ManageContactsSetting is ' + ManageContactsSetting);
        if (ManageContactsSetting != true) {
            // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Cannot save the new contact. Please set WGSettings.ManageContacts to true.'));
        } else {
            // If this is a new contact in an existing account, save it;
            system.debug('just before SavePerson(), newContact is ' + newContact);
            if (newContact.AccountId != null) {
                Insert NewContact;
                personId = newContact.Id;
            }
            // else create a lead
            else {
                List<MatchObject> Matches = identifyOrCreatePerson.MatchesList(newcontact);
                personId = Matches[0].PersonId;
                string stype = Matches[0].Person.getSObjectType().getDescribe().getName();
                system.debug('IOCR results are' + Matches[0]);
            }
            addToList(personId);
            newContactForm = false;
        }
    }

//Submit Data
    public PageReference submitData() {
        List<Opportunity> InsertOpps = new List<Opportunity>();

        // TRANSFER ATTENDEE INFO INTO THE PROPER CAMPAIGNMEMBER FIELDS
        system.debug('UpdateAttendees create the Opps; they include ' + UpdateAttendees);
        For (Attendee a : UpdateAttendees) {
            // SAVE ATTENDEE INFO INTO CAMPAIGN MEMBER
            a.CM.Hours__c = a.Hours;
            a.CM.Supervisor_Satisfaction__c = a.Contribution.Supervisor_Satisfaction__c;
            a.CM.Comments__c = a.Comments;
            a.CM.Leadership_Level__c = a.Contribution.Leadership_Level__c;
            a.CM.Processed__c = true;
            UpdateCMs.add(a.CM);
        }
        InsertOpps = createContributions(UpdateAttendees);

        SYSTEM.DEBUG('After updating CMs from Attendee data, the UpdateCMs list is ' + UpdateCMs);
        if (UpdateCMs.size() > 0) update UpdateCMs; // We set all the CMs in the AttendeeRSVPed list to 'processed' so we won't pull them in the next batch.
        system.debug('InsertOpps is ' + InsertOpps);
        system.debug('UpdateCMs is ' + UpdateCMs);
        if (InsertOpps.size() > 200)
            Id batchId = Database.executeBatch(new OpportunityBatch(InsertOpps), 200); else if (InsertOpps.size() > 0) insert InsertOpps;

        PageReference nextPage = new PageReference('/' + Camp.Id);
        nextPage.setRedirect(true);
        return nextPage;

    }


    public List<Opportunity> createContributions(List<Attendee> ListAttendees) {
        List<Opportunity> ListSubmitOpps = new List<Opportunity>();
        List<Id> UpdateAccountIds = new List<Id>();
        List<Account> UpdateAccounts = new List<Account>();
        List<Lead> LeadsToConvert = new List<Lead>();
        Map<Id, OppAndAttendee> TransMap = new Map<Id, OppAndAttendee>();
        Map<id, List<string>> AcctIdNameMap = new Map<id, List<string>>();
        Database.LeadConvert[] lcList = new List<Database.LeadConvert>();
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true limit 1];

        for (Attendee a : ListAttendees) {
            if (a.Hours > 0) {
                Opportunity opp = new Opportunity(
                        Name = 'autofill',
                        CloseDate = a.Contribution.CloseDate == null ? Camp.Event_Date_Time__c.date() : a.Contribution.CloseDate,
                        Hours_Actual__c = a.Hours,
                        CampaignId = Camp.Id,
                        RecordTypeId = VolContribId,
                        Description = a.Comments,
                        Leadership_Level__c = a.Contribution.Leadership_Level__c,
                        StageName = 'Completed',
                        Supervisor_Satisfaction__c = a.Contribution.Supervisor_Satisfaction__c
                );
                For (Schema.FieldSetMember ppf : pPLFieldSetMembers) {
                    system.debug('Field name is ' + ppf.getFieldPath());
                    Opp.put(ppf.getFieldPath(), a.Contribution.get(ppf.getFieldPath()));
                }
                system.debug('Did I insert values in Opp fields?' + Opp);
                // If this is a lead, add to list of leads to be converted;
                // Create map of LeadId to Attendee and Opp (in OppAndAttendee class)
                // so that I can later pull out the right names for the Account,
                // and assign the contact and account to the contribution.
                system.debug('a.CM.Lead.LastName is ' + a.CM.Lead.LastName + ' and a.CM.Lead.IsConverted is ' + a.CM.Lead.IsConverted);
                if (a.CM.LeadId != null && a.CM.Lead.IsConverted != true) {
                    OppAndAttendee oa = new OppAndAttendee(a, opp);
                    TransMap.put(a.CM.LeadId, oa);
                    system.debug('a.CM.LeadId is ' + a.CM.LeadID);
                    Database.LeadConvert lc = new database.LeadConvert();
                    lc.setLeadId(a.CM.LeadId);
                    lc.setConvertedStatus(convertStatus.MasterLabel);
                    lc.setDoNotCreateOpportunity(true);
                    lcList.add(lc);
                } else {
                    opp.AccountId = a.CM.Contact.AccountId;
                    opp.Contact__c = a.CM.ContactID;
                    ListSubmitOpps.add(opp);
                }
            }
        }
        // Convert List

        if (lcList.size()>0) {
            Database.LeadConvertResult[] lcrs = Database.convertLead(lcList);
            For (Database.LeadConvertResult lcr : lcrs) {
                system.assert(lcr.IsSuccess());
                OppAndAttendee oa = TransMap.get(lcr.getLeadId());
                system.debug('oa is ' + oa);
                oa.opp.Contact__c = lcr.getContactId();
                oa.opp.AccountId = lcr.getAccountId();
                ListSubmitOpps.add(oa.opp);
                Account a = new Account(
                        Id = lcr.getAccountId());
                a.name = oa.at.cm.Lead.LastName + ', ' + oa.at.cm.Lead.FirstName + ' Household';
                a.Dear__c = oa.at.cm.Lead.FirstName;
                a.Addressee__c = oa.at.cm.Lead.FirstName + ' ' + oa.at.cm.Lead.LastName;
                UpdateAccounts.add(a);
            }
        }
        if (UpdateAccounts.size()>0) update UpdateAccounts;
        system.debug('At end of createContributions(), count of new Opps is ' + ListSubmitOpps.size());
        return ListSubmitOpps;
    }


    public void deleteCM() {
        UnprocessedAttendees.remove(AttendeeToDeleteIndex);
        delete CMToDelete;
        UnprocessedAttWrapped = new List<AttendeeWrapper>();
        Integer counter = 0;
        for (Attendee at : UnprocessedAttendees) {
// add the wrapper to the collection
            UnprocessedAttWrapped.add(new AttendeeWrapper(at, counter));
            counter = counter + 1;
        }

    }


//Wrapper Class
    public class Attendee {
        public Id PersonId {get;set;
        }
        public CampaignMember CM { get; set; }
        public Decimal Hours { get; set;
        }
        public String Comments { get; set;
        }
        public String OriginalStatus { get; set;
        }
        public Opportunity Contribution { get; set;
        }

        public Attendee(CampaignMember campmmbr) {
            CM = campmmbr;
            OriginalStatus = CM.Status;
            Contribution = new Opportunity();
            Contribution.Supervisor_Satisfaction__c = DefaultRating;
// Contribution.Leadership_Level__c = DefaultLeadership;
        }

        public Attendee(Campaign Camp) {
            CM = new CampaignMember(CampaignId = Camp.Id);
            OriginalStatus = CM.Status;
            Contribution = new Opportunity();
            Contribution.Supervisor_Satisfaction__c = DefaultRating;
// Contribution.Leadership_Level__c = DefaultLeadership;
        }
    }

    class AttendeeWrapper {
        public Attendee at { get; set; }
        public Integer counter {
            get;
            set;
        }

        public AttendeeWrapper(Attendee at, Integer counter) {
            this.at = at;
            this.counter = counter;
        }
    }


    public class OppAndAttendee{
        public Attendee at {get; set;
        }
        public Opportunity opp {get; set;
        }
        public OppAndAttendee(Attendee att, Opportunity oppor){
            at = att;
            opp = oppor;
        }
    }

    public PageReference DisplayNoCAmpaignWarning() {
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 'Error: Not sure which Campaign to use.  Did you start from the campaign detail page?  Please send a copy of this message to support@watergrass.org.');
        ApexPages.addMessage(myMsg);
        return null;
    }

    public PageReference DisplayBadCampIdWarning() {
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 'That Campaign Id is not correct.  Please send a copy of this message to support@watergrass.org.');
        ApexPages.addMessage(myMsg);
        return null;
    }

    public Boolean getManageContactsSetting(){
        return WGHelpers.getManageContactsSetting();
    }
}