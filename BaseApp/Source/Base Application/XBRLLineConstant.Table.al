table 408 "XBRL Line Constant"
{
    Caption = 'XBRL Line Constant';
    ObsoleteReason = 'XBRL feature will be discontinued';
#if not CLEAN20
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
#endif
    ReplicateData = false;

    fields
    {
        field(1; "XBRL Taxonomy Name"; Code[20])
        {
            Caption = 'XBRL Taxonomy Name';
            TableRelation = "XBRL Taxonomy";
        }
        field(2; "XBRL Taxonomy Line No."; Integer)
        {
            Caption = 'XBRL Taxonomy Line No.';
            TableRelation = "XBRL Taxonomy Line"."Line No." WHERE("XBRL Taxonomy Name" = FIELD("XBRL Taxonomy Name"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(5; "Constant Amount"; Decimal)
        {
            Caption = 'Constant Amount';
        }
        field(6; "Label Language Filter"; Text[10])
        {
            Caption = 'Label Language Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "XBRL Taxonomy Name", "XBRL Taxonomy Line No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "XBRL Taxonomy Name", "XBRL Taxonomy Line No.", "Starting Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("XBRL Taxonomy Name");
    end;
}

