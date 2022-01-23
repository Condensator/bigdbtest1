CREATE TYPE [dbo].[BlueBookValue] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Quarter] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[Year] [int] NOT NULL,
	[Value_Amount] [decimal](16, 2) NULL,
	[Value_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[BlueBookId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
