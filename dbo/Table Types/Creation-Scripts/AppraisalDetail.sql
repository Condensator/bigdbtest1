CREATE TYPE [dbo].[AppraisalDetail] AS TABLE(
	[AppraisalValue_Amount] [decimal](16, 2) NULL,
	[AppraisalValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[InPlaceValue_Amount] [decimal](16, 2) NULL,
	[InPlaceValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[InPlaceCurrencyId] [bigint] NOT NULL,
	[ThirdPartyAppraiserId] [bigint] NULL,
	[AppraisalRequestId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
