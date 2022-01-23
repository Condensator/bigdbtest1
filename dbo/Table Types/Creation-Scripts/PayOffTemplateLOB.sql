CREATE TYPE [dbo].[PayOffTemplateLOB] AS TABLE(
	[DiscountRate] [decimal](8, 4) NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[LineofBusinessId] [bigint] NOT NULL,
	[PayOffTemplateId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
