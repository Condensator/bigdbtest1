CREATE TYPE [dbo].[ReversalLocationDetail_Extract] AS TABLE(
	[LocationId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Country] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[MainDivision] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[StateId] [bigint] NOT NULL,
	[City] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[LocationCode] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsVertexSupportedLocation] [bit] NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[AcquisitionLocationTaxAreaId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
