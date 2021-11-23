public with sharing class AddAccountsToNSOppController {

  // the soql without the order and limit
  private String soql {get;set;}
    
  // the collection of accounts to display
  public List<aAccount> accounts {get;set;}

  public List<aAccount> accountList {get;set;}

  public Id currentOppId{get; set;}
    
  public Integer numberOfAccounts {get;set;}

  // init the controller and display some sample data when the page loads
  public AddAccountsToNSOppController(ApexPages.StandardController controller) {

    currentOppId = controller.getId();
    soql = 'select Name, Parent.Name, BillingState, BillingCity, Near_Site_Opportunity__r.Id FROM Account';
    runQuery();
  }

  // a custom account class to see if the account is selected or not
  public class aAccount {
    public Account acc {get; set;}
    public Boolean selected {get; set;}

    public aAccount(Account a) {
        acc = a;
        selected = false;
    }  
 }

  // adds selected Accounts to the Opportunity
  public PageReference proccessSelected() {
    List<Account> selectedAccounts = new List<Account>();


      if(accountList == null) {
          accountList = new List<aAccount>();
          for(Account a : Database.query(soql + ' order by ' + sortField + ' ' + sortDir + ' limit 20')) {
              accountList.add(new aAccount(a));
          }
      }


      for(aAccount aAcc : accountList) {
          if(aAcc.selected == true) {
              selectedAccounts.add(aAcc.acc);
          }
      }  

      for(Account a : selectedAccounts) {
          a.Near_Site_Opportunity__c = currentOppId;
      }

      update selectedAccounts;
	  numberOfAccounts = selectedAccounts.size();
      selectedAccounts=null;
      return null;
  }

  // the current sort direction. defaults to asc
  public String sortDir {
    get  { if (sortDir == null) {  sortDir = 'asc'; } return sortDir;  }
    set;
  }

  // the current field to sort by. defaults to name
  public String sortField {
    get  { if (sortField == null) {sortField = 'name'; } return sortField;  }
    set;
  }
    
  // toggles the sorting of query from asc<-->desc
  public void toggleSort() {
    // simply toggle the direction
    sortDir = sortDir.equals('asc') ? 'desc' : 'asc';
    // run the query again
    runQuery();
  }

  // runs the actual query
  public void runQuery() {

    try {

          accountList = new List<aAccount>();
          for(Account a : Database.query(soql + ' order by ' + sortField + ' ' + sortDir + ' limit 20')) {
              accountList.add(new aAccount(a));
          }

      accounts = accountList;
    } catch (Exception e) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops!'));
    }

  }

  // runs the search with parameters passed via Javascript
  public PageReference runSearch() {

    String accountName = Apexpages.currentPage().getParameters().get('accountName');

    soql = 'select Name, Parent.Name, BillingCity, BillingState, Near_Site_Opportunity__c FROM Account';

    if (!accountName.equals(''))
      soql += ' WHERE Name LIKE \''+String.escapeSingleQuotes(accountName)+'%\''; 

    runQuery();

    return null;
  }
    
}