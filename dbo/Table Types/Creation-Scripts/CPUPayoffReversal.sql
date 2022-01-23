CREATE TYPE [dbo].[CPUPayoffReversal] AS TABLE(
	[QuoteName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OtherReversalReasonInfo] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CPUPayoffId] [bigint] NOT NULL,
	[CPUContractId] [bigint] NOT NULL,
	[ReversalReasonId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
