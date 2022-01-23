CREATE TYPE [dbo].[Proposal] AS TABLE(
	[OpportunityAmount_Amount] [decimal](16, 2) NOT NULL,
	[OpportunityAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AnticipatedFeeToSource_Amount] [decimal](16, 2) NULL,
	[AnticipatedFeeToSource_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TransactionDescription] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsPreApproved] [bit] NOT NULL,
	[IsSyndicated] [bit] NOT NULL,
	[SyndicationStrategy] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsDataGatheringComplete] [bit] NOT NULL,
	[IsCreditOrAMProposal] [bit] NOT NULL,
	[Status] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[DocumentMethod] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[PreApprovalLOCId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
