pageextension 50251 "Purchase Order SCDNVN" extends "Purchase Order"
{
    actions
    {
        addlast(processing)
        {
            action("Create Shipment SCDNVN")
            {
                ApplicationArea = All;
                Caption = 'Create Sendcloud Shipment';
                Image = Shipment;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Codeunit "Create From Purch Order SCDNVN";
                ToolTip = 'Creates one new Sendcloud shipment for all lines on this purchase order.';
            }
        }
    }
}
