codeunit 50005 "Print Events Demo SCDNVN"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Print Events SCNVN", OnBeforePrintLabel, '', false, false)]
    local procedure PrintEvents_OnBeforePrintLabel(ParcelResponse: Record "Parcel Response SCNVN"; var IsHandled: Boolean)
    var
        Parcel: Record "Parcel SCNVN";
        ShipmentMethod: Record "Shipment Method SCNVN";
    begin
        Parcel.Get(ParcelResponse."Shipment No.", ParcelResponse."Parcel Line No.");
        ShipmentMethod.Get(Parcel."Shipment Method Id");

        if ShipmentMethod.Name = 'Something' then
            IsHandled := true;
    end;
}
