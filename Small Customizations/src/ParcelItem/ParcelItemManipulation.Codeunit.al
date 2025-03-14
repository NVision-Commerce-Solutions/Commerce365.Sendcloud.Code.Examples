codeunit 50007 "Parcel Item SCDNVN"
{
    [EventSubscriber(ObjectType::Table, Database::"Parcel Item SCNVN", 'OnAfterValidateEvent', 'Tariff No.', false, false)]
    local procedure ParcelItemSCNVN_OnAfterValidateEvent_TariffNo(var Rec: Record "Parcel Item SCNVN"; var xRec: Record "Parcel Item SCNVN"; CurrFieldNo: Integer)
    begin
        Rec."Tariff No." := CopyStr(Format(Rec."Tariff No.").Replace(' ', ''), 1, 20);
    end;
}
