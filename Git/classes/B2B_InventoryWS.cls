@RestResource(urlMapping='/B2BInventory/*')
global  class B2B_InventoryWS {

    /*
    Service Name : getInventoryBySKU()
    Type : Get
    return : B2B_Inventory__c object

    this service returns us the data in the Inventory object fields like name,Available_for_Purchase__c ,Comitted__c,Reserved__c using 
    StockKeepingUnit


    */
    @HttpGet
    global static B2B_Inventory__c getInventoryBySKU() {
       RestRequest request = RestContext.request;
       String SKUId = request.requestURI.substring(request.requestURI.lastIndexOf('/')+1);
        
                        B2B_Inventory__c result =  [SELECT Name,Available_for_Purchase__c ,Comitted__c,Reserved__c FROM B2B_Inventory__c 
                        WHERE  Product_Item__r.StockKeepingUnit=: SKUId];
        return result;
    }

    /*
    Service Name : reserveInventoryBySKU()
    Type : PATCH
    return : B2B_Inventory__c object

    this service updates the data in the reserved field of  Inventory object using 
    StockKeepingUnit
    */

    @HttpPatch
    global static B2B_Inventory__c reserveInventoryBySKU() {
        RestRequest request = RestContext.request;
        String SKUId = request.requestURI.substring(request.requestURI.lastIndexOf('/')+1);
        B2B_Inventory__c thisInventory = [SELECT Id,Available_for_Purchase__c ,Comitted__c,Reserved__c 
        FROM B2B_Inventory__c WHERE  Product_Item__r.StockKeepingUnit=: SKUId];
        Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(request.requestbody.tostring());
        for(String fieldName : params.keySet()) {
            thisInventory.put(fieldName, params.get(fieldName));
        }
        update thisInventory;
        return thisInventory;
    }    
}


