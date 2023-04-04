codeunit 50253 "Post Shipment Events SCDNVN"
{
    /// <summary>
    /// With this event subscriber you can tap into the parcel creation process right after the standard solution has formed the parcel object we want to post to Sendcloud. 
    /// So if you have a requirement to add or change any of the fields on the parcel object, then this is where to do that. 
    /// In this case we are adding a field called shipping_method_checkout_name which is one of the few fields which the standard application does not handle. 
    /// Of course we do take precautions to make sure if at some point the field is added to the standard app, our code will still run smoothly. 
    /// </summary>
    /// <param name="ParcelRec"></param>
    /// <param name="Parcel"></param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Post Shipment Events SCNVN", 'OnAfterCreateParcelJson', '', false, false)]
    local procedure PostShipmentEventsSCNVN_OnAfterCreateParcelJson(var ParcelRec: Record "Parcel SCNVN"; var Parcel: JsonObject)
    var
        SalesHeader: Record "Sales Header";
        ShipmentHeaderSCNVN: Record "Shipment Header SCNVN";
        KeyNameTxt: Label 'shipping_method_checkout_name';
        ValueToAdd: JsonValue;
    begin
        if ShipmentHeaderSCNVN.Get(ParcelRec."Shipment No.") then
            if SalesHeader.Get(ShipmentHeaderSCNVN."Order No.") then begin
                ValueToAdd.SetValue(SalesHeader."Your Reference");

                if Parcel.Contains(KeyNameTxt) then
                    Parcel.Replace(KeyNameTxt, ValueToAdd)
                else
                    Parcel.Add(KeyNameTxt, ValueToAdd);
            end;
    end;
}
