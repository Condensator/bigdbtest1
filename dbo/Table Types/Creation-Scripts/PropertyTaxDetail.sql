CREATE TYPE [dbo].[PropertyTaxDetail] AS TABLE(
	[ReportedCost_Amount] [decimal](16, 2) NOT NULL,
	[ReportedCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssessedValue_Amount] [decimal](16, 2) NOT NULL,
	[AssessedValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AdministrativeFee_Amount] [decimal](16, 2) NOT NULL,
	[AdministrativeFee_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[BillToId] [bigint] NOT NULL,
	[PropertyTaxId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
