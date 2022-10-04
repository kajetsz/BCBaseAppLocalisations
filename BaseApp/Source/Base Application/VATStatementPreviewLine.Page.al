page 475 "VAT Statement Preview Line"
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "VAT Statement Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Row No."; Rec."Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that identifies the line.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the VAT statement line.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies what the VAT statement line will include.';
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT statement line shows the VAT amounts, or the base amounts on which the VAT is calculated.';
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("Tax Jurisdiction Code"; Rec."Tax Jurisdiction Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies a tax jurisdiction code for the statement.';
                    Visible = false;
                }
                field("Use Tax"; Rec."Use Tax")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies whether to use only entries from the VAT Entry table that are marked as Use Tax to be totaled on this line.';
                    Visible = false;
                }
                field(ColumnValue; ColumnValue)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankZero = true;
                    Caption = 'Column Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the type of entries that will be included in the amounts in columns.';

                    trigger OnDrillDown()
                    begin
                        case Type of
                            Type::"Account Totaling":
                                begin
                                    SetKeyForGLEntry(GLEntry);
                                    GLEntry.SetFilter("G/L Account No.", "Account Totaling");
                                    SetDateFilterForGLEntry(GLEntry);
                                    if "Document Type" = "Document Type"::"All except Credit Memo" then
                                        GLEntry.SetFilter("Document Type", '<>%1', "Document Type"::"Credit Memo")
                                    else
                                        GLEntry.SetRange("Document Type", "Document Type");
                                    OnColumnValueDrillDownOnBeforeRunGeneralLedgerEntries(VATEntry, GLEntry, Rec);
                                    PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
                                end;
                            Type::"VAT Entry Totaling":
                                begin
                                    VATEntry.Reset();
                                    SetKeyForVATEntry(VATEntry);
                                    VATEntry.SetRange(Type, "Gen. Posting Type");
                                    VATEntry.SetRange("VAT Bus. Posting Group", "VAT Bus. Posting Group");
                                    VATEntry.SetRange("VAT Prod. Posting Group", "VAT Prod. Posting Group");
                                    VATEntry.SetRange("Tax Jurisdiction Code", "Tax Jurisdiction Code");
                                    VATEntry.SetRange("Use Tax", "Use Tax");
                                    if "Document Type" = "Document Type"::"All except Credit Memo" then
                                        VATEntry.SetFilter("Document Type", '<>%1', "Document Type"::"Credit Memo")
                                    else
                                        VATEntry.SetRange("Document Type", "Document Type");
                                    if GetFilter("Date Filter") <> '' then
                                        SetDateFilterForVATEntry(VATEntry);
                                        
                                    case Selection of
                                        Selection::Open:
                                            VATEntry.SetRange(Closed, false);
                                        Selection::Closed:
                                            VATEntry.SetRange(Closed, true);
                                        Selection::"Open and Closed":
                                            VATEntry.SetRange(Closed);
                                    end;
                                    OnBeforeOpenPageVATEntryTotaling(VATEntry, Rec, GLEntry);
                                    PAGE.Run(PAGE::"VAT Entries", VATEntry);
                                end;
                            Type::"Row Totaling",
                            Type::Description:
                                Error(Text000, FieldCaption(Type), Type);
                        end;
                    end;
                }
                field(CorrectionValue; CorrectionValue)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankZero = true;
                    Caption = 'Correction Amount';
                    ToolTip = 'Specifies the amount of the VAT correction. You must enter the correction amount, not the new amount.';

                    trigger OnDrillDown()
                    begin
                        DrillDownCorrectionValue;
                    end;
                }
                field(TotalAmount; ColumnValue + CorrectionValue)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankZero = true;
                    Caption = 'Total Amount';
                    ToolTip = 'Specifies the total amount minus any invoice discount amount for the service order. The value does not include VAT.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Clear(VATStatement);
        VATStatement.InitializeRequest(VATStmtName, Rec, Selection, PeriodSelection, false, UseAmtsInAddCurr);
        CalcColumnValue(Rec, ColumnValue, CorrectionValue, NetAmountLCY, '', 0);
        if "Print with" = "Print with"::"Opposite Sign" then begin
            ColumnValue := -ColumnValue;
            CorrectionValue := -CorrectionValue;
        end;
    end;

    var
        Text000: Label 'Drilldown is not possible when %1 is %2.';

    protected var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        VATStmtName: Record "VAT Statement Name";
        VATStatement: Report "VAT Statement";
        ColumnValue: Decimal;
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        UseAmtsInAddCurr: Boolean;
        CorrectionValue: Decimal;
        NetAmountLCY: Decimal;
        VATDateType: Enum "VAT Date Type";

    local procedure SetKeyForGLEntry(var GLEntryLocal: Record "G/L Entry")
    begin
        case VATDateType of
            VATDateType::"Document Date": GLEntryLocal.SetCurrentKey("Journal Templ. Name", "G/L Account No.", "Document Date", "Document Type");
            VATDateType::"Posting Date": GLEntryLocal.SetCurrentKey("Journal Templ. Name", "G/L Account No.", "Posting Date", "Document Type");
            VATDateType::"VAT Reporting Date": GLEntryLocal.SetCurrentKey("Journal Templ. Name", "G/L Account No.", "VAT Reporting Date", "Document Type");
        end
    end;

    local procedure SetKeyForVATEntry(var VATEntryLocal: Record "VAT Entry")
    begin
        case VATDateType of
            VATDateType::"Document Date": VATEntryLocal.SetCurrentKey("Journal Templ. Name", Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Document Date");
            VATDateType::"Posting Date": VATEntryLocal.SetCurrentKey("Journal Templ. Name", Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date");
            VATDateType::"VAT Reporting Date": VATEntryLocal.SetCurrentKey("Journal Templ. Name", Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date");
        end
    end;

    local procedure SetDateFilterForGLEntry(var GLEntryLocal: Record "G/L Entry")
    begin
        case VATDateType of
            VATDateType::"Document Date": Rec.CopyFilter("Date Filter", GLEntryLocal."Document Date");
            VATDateType::"Posting Date": Rec.CopyFilter("Date Filter", GLEntryLocal."Posting Date");
            VATDateType::"VAT Reporting Date": Rec.CopyFilter("Date Filter", GLEntryLocal."VAT Reporting Date");
        end
    end;

    local procedure SetDateFilterForVATEntry(var VATEntryLocal: Record "VAT Entry")
    begin
        if PeriodSelection = PeriodSelection::"Before and Within Period" then
            case VATDateType of
                VATDateType::"Document Date": VATEntryLocal.SetRange("Document Date", 0D, Rec.GetRangeMax("Date Filter"));
                VATDateType::"Posting Date": VATEntryLocal.SetRange("Posting Date", 0D, Rec.GetRangeMax("Date Filter"));
                VATDateType::"VAT Reporting Date": VATEntryLocal.SetRange("VAT Reporting Date", 0D, Rec.GetRangeMax("Date Filter"));
            end
        else
            case VATDateType of
                VATDateType::"Document Date": Rec.CopyFilter("Date Filter", VATEntryLocal."Document Date");
                VATDateType::"Posting Date": Rec.CopyFilter("Date Filter", VATEntryLocal."Posting Date");
                VATDateType::"VAT Reporting Date": Rec.CopyFilter("Date Filter", VATEntryLocal."VAT Reporting Date");
            end
    end;

    local procedure CalcColumnValue(VATStatementLine: Record "VAT Statement Line"; var ColumnValue: Decimal; var CorrectionValue: Decimal; var NetAmountLCY: Decimal; JournalTempl: Code[10]; Level: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcColumnValue(VATStatementLine, ColumnValue, CorrectionValue, NetAmountLCY, JournalTempl, Level, IsHandled, Selection, PeriodSelection, false, UseAmtsInAddCurr);
        if IsHandled then
            exit;

        VATStatement.CalcLineTotal(VATStatementLine, ColumnValue, CorrectionValue, NetAmountLCY, JournalTempl, Level);
    end;

    procedure UpdateForm(var VATStmtName: Record "VAT Statement Name"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewUseAmtsInAddCurr: Boolean; NewVATDateType: Enum "VAT Date Type")
    begin
        VATStmtName.CopyFilter("Date Filter", "Date Filter");
        Selection := NewSelection;
        PeriodSelection := NewPeriodSelection;
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
        VATDateType := NewVATDateType;
        VATStatement.InitializeRequest(VATStmtName, Rec, Selection, PeriodSelection, false, UseAmtsInAddCurr, NewVATDateType);
        OnUpdateFormOnBeforePageUpdate2(VATStmtName, Rec, Selection, PeriodSelection, false, UseAmtsInAddCurr, NewVATDateType);
        CurrPage.Update();

        OnAfterUpdateForm();
    end;

#if not CLEAN21
    [Obsolete('Replaced by UpdateForm(var VATStmtName: Record "VAT Statement Name"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewUseAmtsInAddCurr: Boolean; NewVATDateType: Enum "VAT Date Type")', '21.0')]
    procedure UpdateForm(var VATStmtName: Record "VAT Statement Name"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewUseAmtsInAddCurr: Boolean)
    begin
        VATStmtName.CopyFilter("Date Filter", "Date Filter");
        Selection := NewSelection;
        PeriodSelection := NewPeriodSelection;
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
        VATStatement.InitializeRequest(VATStmtName, Rec, Selection, PeriodSelection, false, UseAmtsInAddCurr);
        OnUpdateFormOnBeforePageUpdate(VATStmtName, Rec, Selection, PeriodSelection, false, UseAmtsInAddCurr);
        CurrPage.Update();

        OnAfterUpdateForm();
    end;
#endif

    local procedure ApplyDateFilter(var ManualVATCorrection: Record "Manual VAT Correction")
    begin
        if GetFilter("Date Filter") <> '' then
            if PeriodSelection = PeriodSelection::"Before and Within Period" then
                ManualVATCorrection.SetRange("Posting Date", 0D, GetRangeMax("Date Filter"))
            else
                CopyFilter("Date Filter", ManualVATCorrection."Posting Date");
    end;

    procedure DrillDownCorrectionValue()
    var
        ManualVATCorrection: Record "Manual VAT Correction";
        ManualVATCorrectionListPage: Page "Manual VAT Correction List";
        IncludesRowTotaling: Boolean;
    begin
        Clear(ManualVATCorrectionListPage);
        ManualVATCorrection.Reset();
        ManualVATCorrection.FilterGroup(2);
        IncludesRowTotaling := MarkManVATCorrections(Rec, ManualVATCorrection);
        if IncludesRowTotaling then begin
            ManualVATCorrectionListPage.SetCorrStatementLineNo("Line No.");
            ManualVATCorrection.SetRange("Statement Line No.");
            ManualVATCorrection.MarkedOnly(true);
        end;
        ManualVATCorrection.FilterGroup(0);
        ManualVATCorrectionListPage.SetTableView(ManualVATCorrection);
        ManualVATCorrectionListPage.Run();
    end;

    local procedure MarkLinesManVATCorrections(VATStatementLine: Record "VAT Statement Line"; var ManualVATCorrection: Record "Manual VAT Correction")
    begin
        ManualVATCorrection.SetRange("Statement Template Name", VATStatementLine."Statement Template Name");
        ManualVATCorrection.SetRange("Statement Name", VATStatementLine."Statement Name");
        ManualVATCorrection.SetRange("Statement Line No.", VATStatementLine."Line No.");
        ApplyDateFilter(ManualVATCorrection);
        if ManualVATCorrection.FindSet() then
            repeat
                ManualVATCorrection.Mark(true);
            until ManualVATCorrection.Next() = 0;
    end;

    local procedure MarkManVATCorrections(VATStatementLine: Record "VAT Statement Line"; var ManualVATCorrection: Record "Manual VAT Correction"): Boolean
    begin
        MarkLinesManVATCorrections(VATStatementLine, ManualVATCorrection);
        if (VATStatementLine.Type = VATStatementLine.Type::"Row Totaling") and
           (VATStatementLine."Row Totaling" <> '')
        then begin
            VATStatementLine.SetRange("Statement Template Name", VATStatementLine."Statement Template Name");
            VATStatementLine.SetRange("Statement Name", VATStatementLine."Statement Name");
            VATStatementLine.SetFilter("Row No.", VATStatementLine."Row Totaling");
            if VATStatementLine.FindSet() then
                repeat
                    MarkManVATCorrections(VATStatementLine, ManualVATCorrection);
                until VATStatementLine.Next() = 0;
            exit(true);
        end;
        exit(false);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCalcColumnValue(VATStatementLine: Record "VAT Statement Line"; var TotalAmount: Decimal; var CorrectionValue: Decimal; var NetAmountLCY: Decimal; JournalTempl: Code[10]; Level: Integer; var IsHandled: Boolean; Selection: Enum "VAT Statement Report Selection"; PeriodSelection: Enum "VAT Statement Report Period Selection"; PrintInIntegers: Boolean; UseAmtsInAddCurr: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOpenPageVATEntryTotaling(var VATEntry: Record "VAT Entry"; var VATStatementLine: Record "VAT Statement Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnColumnValueDrillDownOnBeforeRunGeneralLedgerEntries(var VATEntry: Record "VAT Entry"; var GLEntry: Record "G/L Entry"; var VATStatementLine: Record "VAT Statement Line")
    begin
    end;

#if not CLEAN21
    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by OnUpdateFormOnBeforePageUpdate2(var NewVATStmtName: Record "VAT Statement Name"; var NewVATStatementLine: Record "VAT Statement Line"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewPrintInIntegers: Boolean; NewUseAmtsInAddCurr: Boolean; VATDateType: Enum "VAT Date Type")', '21.0')]
    local procedure OnUpdateFormOnBeforePageUpdate(var NewVATStmtName: Record "VAT Statement Name"; var NewVATStatementLine: Record "VAT Statement Line"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewPrintInIntegers: Boolean; NewUseAmtsInAddCurr: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnUpdateFormOnBeforePageUpdate2(var NewVATStmtName: Record "VAT Statement Name"; var NewVATStatementLine: Record "VAT Statement Line"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewPrintInIntegers: Boolean; NewUseAmtsInAddCurr: Boolean; NewVATDateType: Enum "VAT Date Type")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateForm()
    begin
    end;
}

