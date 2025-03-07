/**
 * Created by Baird on 3/14/2019.
 * Deployed to all instances on 11 May 2020
 */

public with sharing class WGHelpTab {
    public string OrgID18 {get; set;}
    public string BaseURL {get; set;}

    public WGHelpTab(){
        OrgID18 = [select id from Organization].Id;

        Try {
            Site Sitio = [select MasterLabel, Name, Status, Subdomain,
                    Description, UrlPathPrefix, GuestUserId
            from Site where MasterLabel = :'Signup' LIMIT 1];
            SiteDetail mySiteDetail = [select SecureURL from SiteDetail where DurableId = :Sitio.Id];
            System.debug(mySiteDetail.SecureURL);
            if(Test.isRunningTest()){
                BaseURL = 'BaseURL';
            }else{
                BaseUrl = mySiteDetail.SecureURL + '/';
                system.debug('In controller, BaseURL is calculated to be ' + BaseURL);
            }
        } catch (QueryException e) {
            System.debug(e.getMessage());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'Sorry, cannot find the site named Signup, which is required for WG signup pages.  Please go to Setup / Sites and rename your default site to Signup.'));
        }
    }
}