CREATE TYPE [dbo].[LoanPrepaymentPenaltyTemplateDetail] AS TABLE(
	[RowNumber] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FromMonth] [int] NULL,
	[ToMonth] [int] NULL,
	[Percentage] [decimal](5, 2) NULL,
	[IsActive] [bit] NOT NULL,
	[LoanPrepaymentPenaltyTemplateId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
