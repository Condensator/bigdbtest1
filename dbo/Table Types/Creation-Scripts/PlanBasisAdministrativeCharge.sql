CREATE TYPE [dbo].[PlanBasisAdministrativeCharge] AS TABLE(
	[RowNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MinimumTransaction_Amount] [decimal](16, 2) NOT NULL,
	[MinimumTransaction_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[MaximumTransaction_Amount] [decimal](16, 2) NOT NULL,
	[MaximumTransaction_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AdministrativeCost_Amount] [decimal](16, 2) NOT NULL,
	[AdministrativeCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[COFAdjustment] [decimal](9, 5) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[PlanBaseId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
