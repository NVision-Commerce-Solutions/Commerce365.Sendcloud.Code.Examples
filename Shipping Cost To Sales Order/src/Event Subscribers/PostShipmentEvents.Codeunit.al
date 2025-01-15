codeunit 50253 "Post Shipment Events SCDNVN"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SSH Shipment Events SCNVN", 'OnAfterCreateShipment', '', false, false)]
    local procedure SSHShipmentEventsSCNVN_OnAfterCreateShipment(var SalesShipmentHeader: Record "Sales Shipment Header"; var ShipmentHeader: Record "Shipment Header SCNVN");
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Parcel: Record "Parcel SCNVN";
        DocumentType: Enum "Sales Document Type";
        LineNo: Integer;
        TotalValue: Decimal;
    begin
        Parcel.SetRange("Shipment No.", ShipmentHeader."No.");
        if Parcel.FindSet() then
            repeat
                TotalValue += Parcel.Price;
            until Parcel.Next() = 0;

        if TotalValue = 0 then
            TotalValue := 5.95;

        if SalesHeader.Get(DocumentType::Order, SalesShipmentHeader."Order No.") then begin
            LineNo := GetNextSalesLineNo(SalesHeader);
            SalesLine.Init();
            SalesLine.Validate("Document Type", SalesHeader."Document Type");
            SalesLine.Validate("Document No.", SalesHeader."No.");
            SalesLine.Validate("Line No.", LineNo);
            SalesLine.Insert(true);

            SalesLine.Validate(Type, SalesLine.Type::Item);
            SalesLine.Validate("No.", '1051');
            SalesLine.Validate("Line Amount", TotalValue);
            SalesLine.Modify(true);
        end;
    end;

    local procedure GetNextSalesLineNo(var SalesHeader: Record "Sales Header"): Integer
    var
        SalesLine2: Record "Sales Line";
    begin
        SalesLine2.Reset();
        SalesLine2.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine2.SetRange("Document No.", SalesHeader."No.");
        if SalesLine2.FindLast() then
            exit(SalesLine2."Line No." + 10000)
        else
            exit(10000);
    end;
}
