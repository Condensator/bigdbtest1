CREATE TYPE [dbo].[CreditBureauRqstBusinessReasonCode] AS TABLE(
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ModelReasonConfigId] [bigint] NOT NULL,
	[CreditBureauRqstBusinessId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
