@RestResource(urlMapping='/B2BInventorys/*')
global class B2B_commitWs {
    
    /*
    Service Name : commitInventoryBySKU()
    Type : PATCH
    return : B2B_Inventory__c object

    this service updates the data in the comitted field of  Inventory object using 
    StockKeepingUnit
    */
    @HttpPatch
    global static B2B_Inventory__c commitInventoryBySKU() {
        RestRequest request = RestContext.request;
        String SKUId = request.requestURI.substring(request.requestURI.lastIndexOf('/')+1);
        B2B_Inventory__c thisInventory = [SELECT Id,Reserved__c,Comitted__c FROM B2B_Inventory__c WHERE  Product_Item__r.StockKeepingUnit=: SKUId];
        Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(request.requestbody.tostring());
        for(String fieldName : params.keySet()) {

            if(fieldName=='Comitted__c'){
                String qty=String.valueOf(params.get(fieldName));

                thisInventory.Comitted__c +=Decimal.valueOf(qty);

                thisInventory.Reserved__c -=Decimal.valueOf(qty);

            }
            else
            {
                thisInventory.put(fieldName, params.get(fieldName));

            }
            
        }
        update thisInventory;
        return thisInventory;
    }    

    
}

 
