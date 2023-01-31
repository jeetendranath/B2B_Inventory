
public class B2BInventory_Class {
  /*
  Method Name : getSKU()
  Parameters : productId of type String
  return type : String

  This method takes the productId parameter and gets the StockKeepingUnit using SOQL
  and retrurns the String value.

  */

  @AuraEnabled
  public static String getSKU(String productId){
    try {
    List <Product2> productList = [SELECT StockKeepingUnit FROM Product2 WHERE Id =: productId];  
    String SKU =productList[0].StockKeepingUnit;
    return SKU;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

   /*
  Method Name : getStockBySKU()
  Parameters : productId of type String
  return type : Map<String,Decimal>

  This method sends the request to the webservice API of GET method and gets the Inventory details using SKU 
  and returns the result in Map<String,Decimal>.

  */

  @AuraEnabled
  public static Map<String,Decimal> getStockBySKU(String productId)
  {
    try{
    String SKU = getSKU(productId);
    Map<String,Decimal> result1 = new Map<String,Decimal>();
    Http http = new Http();
    HttpRequest request = new HttpRequest();
    request.setEndpoint(Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/B2BInventory/' +SKU);
    request.setMethod('GET');
    request.setHeader('Authorization','Bearer ' +UserInfo.getSessionId());
    request.setHeader('Content-Type', 'application/json');
    HttpResponse response = http.send(request);
   
    if (response.getStatusCode() == 200)
    {      
      Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());        
      result1.put('qty',(Decimal) results.get('Available_for_Purchase__c'));
      result1.put('reservedQTY',(Decimal) results.get('Reserved__c'));
      result1.put('commitQTY',(Decimal) results.get('Comitted__c'));   
    } 
    return result1;
  }catch(Exception e)
  {
    throw new AuraHandledException(e.getMessage());
  } 
  }

   /*
  Method Name : updateReservedBySKU()
  Parameters : productId of type STRING , reserveQty of tyype DECIMAL
  return type : Map<String,Object>

  This method sends the request to the webservice API of PATCH method and updates the reserved__c field in Inventory using SKU 
  and returns the result in Map<String,Object>.

  */

  @AuraEnabled
  public static Map<String,Object> updateReservedBySKU(String productId, Decimal reserveQty){
    try{


      Map<String, Object> results = new Map<String,Object>();  
      String SKU = getSKU(productId);
      Map<String,Decimal> Map1 = new Map<String,Decimal>();
      Map1 = getStockBySKU(productId);    
      Decimal totalReserveQty =  Map1.get('reservedQTY') + reserveQty;
      Http http = new Http();
      HttpRequest request = new HttpRequest();
      request.setEndpoint(Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/B2BInventory/' +SKU);
      request.setMethod('PATCH');
      request.setHeader('Authorization','Bearer ' +UserInfo.getSessionId());
      request.setBody('{"Reserved__c":'+totalReserveQty+'}');
      HttpResponse response = http.send(request);
      if(response.getStatusCode() == 200)  {    
        results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
      }
    return results;
    }catch(Exception e){
      throw new AuraHandledException(e.getMessage());
    }      
  }

   /*
  Method Name : updateCommitBySKU()
  Parameters : orderId of type STRING
  return type : Map<String,Object>

  This method sends the request to the webservice API of PATCH method and updates the comitted__c field in Inventory using SKU 
  and returns the result in Map<String,Object>.

  */

  @AuraEnabled
  public static Map<String,Object> updateCommitBySKU(List<Id> orderId){
    try{
      Map<String, Object> results = new Map<String,Object>();
      List<OrderItemSummary> orderItemSummaryList = [SELECT Product2Id, Quantity , OrderSummaryId,StockKeepingUnit  FROM OrderItemSummary WHERE OrderSummaryId=: orderId];
      for(OrderItemSummary t : orderItemSummaryList){
        if(t.StockKeepingUnit != null)
          {        
            String SKU =t.StockKeepingUnit;
                   
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/B2BInventorys/' +SKU);
            request.setMethod('PATCH');
            request.setHeader('Authorization','Bearer ' +UserInfo.getSessionId());    
           
           request.setBody('{"Comitted__c":'+t.Quantity+'}');

            HttpResponse response = http.send(request);
            System.debug(response);

            if (response.getStatusCode() == 200){

              results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
              System.debug(results);
            }
          }
          
      }
      return results;
    }catch(Exception e)
    {
      throw new AuraHandledException(e.getMessage());
    }
    
  }


  /*
  Method Name : createCaseNew()
  Parameters : Id of type String
  return type : Boolean

  This method takes the Id of user to create the case and returns the Boolean value.
  */
  
  @AuraEnabled
  public static Boolean createCaseNew(String id){

    try{
      if(id != null){
      list<user> userlist = [SELECT u.Id ,u.ContactId FROM user u WHERE u.Id =:id ];
          
      case case1 = new Case();
      case1.Comments = 'We will notify you';
      case1.ContactId = userlist[0].ContactId;
      case1.OwnerId = userlist[0].Id;
      insert case1;

      return true;
      }
      else {
        return false;
      }
    }catch (Exception e){
        throw new AuraHandledException(e.getMessage());
    }
  }

  /*
  Method Name : getCartItemDetails()
  Parameters : Id of type String
  return type : Map<String,Decimal>

  This method takes the Id of Item in the cart and gets the details about the product.
  */

  @AuraEnabled
  public static Map<String,Decimal> getCartItemDetails(String itemId){
     
    try {
      List<CartItem> cartItemList = [SELECT Sku,Product2Id,Quantity FROM CartItem WHERE Id =: itemId];
      System.debug(cartItemList);
      Map<String,Decimal> returnMap = new Map<String,Decimal>();
      returnMap.put('QTY' , cartItemList[0].Quantity);
      return returnMap;
      
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }


  /*
  Method Name : updateReservedCart()
  Parameters : cartItemId of type Id and oldQTY , newQTY of type Decimal
  return type : String

  This method updates the reverse quantity in the B2B_Inventory of the product by calling the "updateReservedBySKU" to request the 
  webservice
  */

  @AuraEnabled
  public static String updateReservedCart(Decimal oldQTY , Decimal newQTY,Id cartItemId){
    try {
      List<CartItem> cartItemList = [SELECT Sku,Product2Id FROM CartItem WHERE Id =: cartItemId]; 
      Id productId = cartItemList[0].Product2Id;
      Map<String,Decimal> Map1 = new Map<String,Decimal>();
      Map1 = getStockBySKU(productId);    
      Decimal ReservedQty =  Map1.get('reservedQTY');
      Decimal availableQTY = Map1.get('qty');           
      Decimal newReservedQTY = (newQTY - oldQTY); 
      Map<String,Object> Map2 = new Map<String,Decimal>();
      Map2 = updateReservedBySKU(productId, newReservedQTY);
      System.debug('Success');
      return 'Success';
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

   /*
  Method Name : isQuantityAvailable()
  Parameters : cartItemId of type Id and QTY of type Decimal
  return type : Boolean

  This method checks wheather the product as the available quantity by calling the "getStockBySKU" and
  returns wheather quantity available ot not.
  */

  @AuraEnabled
  public static Boolean isQuantityAvailable(Id cartItemid, Decimal QTY){
    try {
      List<CartItem> cartItemList = [SELECT Sku,Product2Id,Quantity FROM CartItem WHERE Id =: cartItemid]; 
      Id productId = cartItemList[0].Product2Id;
    
      Map<String,Decimal> Map1 = new Map<String,Decimal>();
      Map1 = getStockBySKU(productId);    
     
      Decimal availableQTY = Map1.get('qty')+ cartItemList[0].Quantity;
      if(QTY > availableQTY)
      {
        return true;
      }
      else {
        return false;
      }
              
           
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /*
  Method Name : cartItemDelete()
  Parameters : cartItemId of type Id
  return type : String

  This method updates the reserved quantity in the B2B_Inventory__c when the items get removed from the cart.
  */

   

  @AuraEnabled
  public static String cartItemDelete(Id cartItemId){
    try {
      Map<String, Object> results = new Map<String,Object>();
      List<CartItem> cartItemList = [SELECT Sku,Product2Id,Quantity FROM CartItem WHERE Id =: cartItemId]; 
      Id productId = cartItemList[0].Product2Id;
      Decimal itemQTY = cartItemList[0].Quantity;
      String SKU = cartItemList[0].Sku;
      Map<String,Decimal> Map1 = new Map<String,Decimal>();
      Map1 = getStockBySKU(productId);    
      Decimal ReservedQty =  Map1.get('reservedQTY');
      Decimal newReservedQTY = ReservedQty - itemQTY;
      Http http = new Http();
      HttpRequest request = new HttpRequest();
      request.setEndpoint(Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/B2BInventory/' +SKU);
      request.setMethod('PATCH');
      request.setHeader('Authorization','Bearer ' +UserInfo.getSessionId());
      request.setBody('{"Reserved__c":'+newReservedQTY+'}');
      HttpResponse response = http.send(request);
      if(response.getStatusCode() == 200)  {    
        results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
      }
      System.debug(results);
      System.debug('Deleted');
      return 'Deleted' ;

      
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /*
  Method Name : clearCartHandle()
  Parameters : cartId of type Id
  return type : String

  This method updates the reserved quantity in the B2B_Inventory__c of every item in the cart when user clicks on clear cart.
  */

  @AuraEnabled
  public static string clearCartHandle(Id cartId){
    try {
      Map<String, Object> results = new Map<String,Object>();
      List<CartItem> cartItemList = [SELECT Sku,Product2Id,Quantity FROM CartItem WHERE CartId =: cartId];

      for(CartItem t : cartItemList){
        if(t.Sku != null)
          {        
            String SKU =t.Sku;
            Decimal itemQTY = t.Quantity;
            Map<String,Decimal> Map1 = new Map<String,Decimal>();
            Map1 = getStockBySKU(t.Product2Id);    
            Decimal ReservedQty =  Map1.get('reservedQTY');
            Decimal newReservedQTY = ReservedQty - itemQTY;                   
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/B2BInventory/' +SKU);
            request.setMethod('PATCH');
            request.setHeader('Authorization','Bearer ' +UserInfo.getSessionId());    
           // request.setBody('{"Comitted__c":'+totalCommitQty+',"Reserved__c":'+updateReserveQty+'}');
            request.setBody('{"Reserved__c":'+newReservedQTY+'}');
            HttpResponse response = http.send(request);
            System.debug(response);

            if (response.getStatusCode() == 200){

              results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
              System.debug(results);
            }
            System.debug('Deleted '+t+results);
            
          }
          
      }
      Return 'Cart Cleared' ;


      
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}






