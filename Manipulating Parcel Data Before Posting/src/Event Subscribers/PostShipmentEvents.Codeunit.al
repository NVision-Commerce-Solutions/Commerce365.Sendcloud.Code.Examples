codeunit 50253 "Post Shipment Events SCDNVN"
{
    /// <summary>
    /// With this event subscriber you can tap into the parcel creation process right after the standard solution has formed the parcel object we want to post to Sendcloud. 
    /// So if you have a requirement to add or change any of the fields on the parcel object, then this is where to do that. 
    /// In 
    /// </summary>
    /// <param name="ParcelRec"></param>
    /// <param name="Parcel"></param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Post Shipment Events SCNVN", 'OnAfterCreateParcelJson', '', false, false)]
    local procedure PostShipmentEventsSCNVN_OnAfterCreateParcelJson(var ParcelRec: Record "Parcel SCNVN"; var Parcel: JsonObject)
    var
        SalesHeader: Record "Sales Header";
        ShipmentHeaderSCNVN: Record "Shipment Header SCNVN";
        ValueToAdd: JsonValue;
    begin
        if ShipmentHeaderSCNVN.Get(ParcelRec."Shipment No.") then
            if SalesHeader.Get(ShipmentHeaderSCNVN."Order No.") then begin
                ValueToAdd.SetValue(SalesHeader."Your_Custom_Field");
                Parcel.Add('shipping_method_checkout_name', ValueToAdd);
            end;
    end;
}
