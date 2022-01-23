CREATE TYPE [dbo].[ProgramRateCardParameter] AS TABLE(
	[ParameterNumber] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsBlankAllowed] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ProgramParameterId] [bigint] NOT NULL,
	[ProgramDetailId] [bigint] NULL,
	[ProgramRateCardId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
